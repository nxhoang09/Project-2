import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodels/activity_viewmodel.dart';
import '../utils/date_utils.dart';
import '../utils/responsive_utils.dart';

class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(ActivityViewModel());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final contentWidth = ResponsiveUtils.getContentMaxWidth(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(context, isDark)),
          Center(
            child: SizedBox(
              width: contentWidth,
              child: Obx(() {
                final logs = viewModel.filteredLogs;
                final isLoading = viewModel.isLoading.value;
                final isLoadMore = viewModel.isLoadMore.value;

                // Tính toán tổng số lượng item trong List
                int itemCount = 1; // Luôn có 1 item đầu tiên là bảng Header
                
                if (isLoading && logs.isEmpty) {
                  itemCount += 1; // Dành 1 ô cho vòng xoay Loading
                } else if (!isLoading && logs.isEmpty) {
                  itemCount += 1; // Dành 1 ô cho chữ "Không có dữ liệu"
                } else {
                  itemCount += logs.length; // Số lượng log thực tế
                  if (isLoadMore) {
                    itemCount += 1; // Dành 1 ô cho vòng xoay Load More ở cuối
                  }
                }

                return ListView.builder(
                  controller: viewModel.scrollController,
                  // Đưa toàn bộ padding trang vào trong ListView để Header cách lề trên chuẩn xác
                  padding: EdgeInsets.fromLTRB(
                    pagePadding.left,
                    pagePadding.top,
                    pagePadding.right,
                    pagePadding.bottom,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    // --- 1. ITEM ĐẦU TIÊN: BẢNG HEADER CHỌN KHÓA ---
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildHeaderCard(context, viewModel),
                      );
                    }

                    // --- 2. TRẠNG THÁI LOADING (Khi danh sách trống) ---
                    if (isLoading && logs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // --- 3. TRẠNG THÁI TRỐNG DỮ LIỆU ---
                    if (!isLoading && logs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text('Không có dữ liệu.')),
                      );
                    }

                    // --- 4. DANH SÁCH NHẬT KÝ THỰC TẾ ---
                    final logIndex = index - 1; // Trừ đi 1 index của Header

                    // Nếu đang tải thêm dữ liệu ở cuối danh sách (Load More)
                    if (logIndex == logs.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 24, height: 24, 
                            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2)
                          )
                        ),
                      );
                    }

                    // Nội dung Log bình thường
                    final currentLog = logs[logIndex];
                    bool showHeader = false;
                    
                    if (logIndex == 0) {
                      showHeader = true;
                    } else {
                      final previousLog = logs[logIndex - 1];
                      showHeader = !MyDateUtils.isSameDay(currentLog['timestamp'], previousLog['timestamp']);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) ...[
                          Padding(
                            padding: EdgeInsets.only(bottom: 12, top: logIndex == 0 ? 0 : 28),
                            child: Text(
                              MyDateUtils.getDateHeader(currentLog['timestamp']),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 12,
                                letterSpacing: 1.1,
                              )
                            ),
                          ),
                        ],
                        _buildTimelineItem(
                          context, 
                          currentLog, 
                          isLast: logIndex == logs.length - 1
                        ),
                      ],
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0C1425), const Color(0xFF0E1A2E)]
              : [const Color(0xFFF6F8FF), const Color(0xFFF8FBF9)],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ActivityViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Access Logs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Monitor real-time entry and exit activity.', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 16),
          Obx(() {
            final items = viewModel.dropdownDevices;
            final selectedValue = viewModel.dropdownValue;
            if (items.isEmpty || selectedValue == null) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
                ),
                child: Text(
                  'Chưa có khóa để hiển thị.',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedValue,
                  items: items.map((dev) {
                    final rawName = dev['name']?.toString() ?? '';
                    final name = rawName.trim().isEmpty ? 'Thiết bị' : rawName;
                    final isDeleted = dev['is_deleted'] == true;
                    final label = isDeleted && !name.contains('(đã xóa)') ? '$name (đã xóa)' : name;
                    return DropdownMenuItem<String>(
                      value: dev['id']?.toString() ?? '',
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && val.isNotEmpty) {
                      viewModel.changeDevice(val);
                    }
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Obx(() => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterChip(context, 'Tất cả', 'all', viewModel),
              _buildFilterChip(context, 'Thành viên', 'member', viewModel),
              _buildFilterChip(context, 'Cảnh báo', 'alert', viewModel),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, ActivityViewModel vm) {
    bool isSelected = vm.currentFilter.value == value;
    return GestureDetector(
      onTap: () => vm.applyFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Text(
          label, 
          style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, dynamic log, {required bool isLast}) {
    final eventType = log['event_type']?.toString() ?? '';
    final isAlert = eventType == 'INTRUDER_ALARM';
    final isApp = eventType.startsWith('APP_UNLOCK_');
    final isUnlockFailed = eventType.endsWith('_FAILED') || eventType == 'UNLOCK_FAILED';
    final deviceName = log['device_name_snapshot']?.toString() ?? '';
    final hasDeviceName = deviceName.trim().isNotEmpty;

    Color mainColor = (isAlert || isUnlockFailed) ? const Color(0xFFBA1A1A) : const Color(0xFF1F7A5A);
    IconData iconData = isAlert
        ? Icons.warning_amber_rounded
        : isUnlockFailed
            ? Icons.error_outline
            : Icons.check_circle_outline;

    String methodText = '';
    IconData methodIcon = Icons.key;
    if (isAlert) {
      methodText = 'Nhận diện khuôn mặt thất bại';
      methodIcon = Icons.face_retouching_off;
    } else if (isApp) {
      methodText = 'Ứng dụng di động';
      methodIcon = Icons.phone_android;
    } else {
      methodText = 'Khuôn mặt';
      methodIcon = Icons.face;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CỘT TRÁI: Dòng kẻ + Icon
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: mainColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(iconData, color: mainColor, size: 20),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5))),
            ],
          ),
          const SizedBox(width: 16),
          
          // CỘT PHẢI: Nội dung Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAlert
                        ? mainColor.withOpacity(0.4)
                        : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(
                          isAlert
                              ? 'CẢNH BÁO: ${log['actor_name']}'
                              : isUnlockFailed
                                  ? '${log['actor_name']} mở cửa thất bại'
                                  : '${log['actor_name']} đã mở cửa',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: (isAlert || isUnlockFailed) ? mainColor : null),
                        )),
                        Text(
                          MyDateUtils.formatTime(log['timestamp']).split(' - ')[0], 
                          style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hasDeviceName) ...[
                      Row(
                        children: [
                          Icon(Icons.lock_outline, size: 16, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              deviceName,
                              style: TextStyle(color: Theme.of(context).colorScheme.outline),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        Icon(methodIcon, size: 16, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 6),
                        Text(methodText, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
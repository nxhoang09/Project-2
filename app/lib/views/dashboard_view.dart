import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import 'package:dotted_border/dotted_border.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/main_wrapper_viewmodel.dart';
import 'add_lock_step1_view.dart';
import 'device_share_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(DashboardViewModel());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final contentWidth = ResponsiveUtils.getContentMaxWidth(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(context, isDark)),
          
          RefreshIndicator(
            onRefresh: () => viewModel.fetchDevices(showLoadingIndicator: false), 
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Padding(
                padding: pagePadding,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      Obx(() => _buildOverviewCard(context, viewModel)),
                      const SizedBox(height: 24),
                      Obx(() {
                        if (viewModel.isLoading.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(), 
                          );
                        }

                        if (viewModel.devices.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Text("Bạn chưa có khóa nào. Hãy thêm mới!"),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth;
                            final columns = maxWidth >= 900 ? 2 : 1;
                            final spacing = 16.0;
                            final itemWidth = columns == 1 ? maxWidth : (maxWidth - spacing) / columns;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: 16,
                              children: viewModel.devices.map((device) {
                                final deviceId = device['id']?.toString() ?? '';
                                final status = device['status']?.toString() ??
                                    ((device['is_online'] == true) ? 'ONLINE' : 'OFFLINE');
                                final isOwner = device['is_owner'] == true;
                                return SizedBox(
                                  width: itemWidth,
                                  child: _buildCompactLockCard(
                                    context: context,
                                    deviceId: deviceId,
                                    title: device['name'],
                                    status: status, 
                                    onUnlock: () => viewModel.unlock(deviceId),
                                    viewModel: viewModel,
                                    isOwner: isOwner,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      }),

                      const SizedBox(height: 8),

                      // NÚT THÊM KHÓA MỚI
                      DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          strokeWidth: 1.5,
                          dashPattern: const [6, 4], 
                          radius: const Radius.circular(20), 
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 72, 
                          child: TextButton(
                            onPressed: () {
                              Get.to(() => const AddLockStep1View());
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                    shape: BoxShape.circle
                                  ),
                                  child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Thêm Khóa Mới',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  )
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // HAI NÚT QUICK ACTION
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final columns = maxWidth >= 700 ? 2 : 1;
                          final spacing = 16.0;
                          final itemWidth = columns == 1 ? maxWidth : (maxWidth - spacing) / columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: itemWidth,
                                child: _buildQuickActionCard(
                                  context,
                                  Icons.person_add_alt_1_outlined,
                                  'Thêm Thành Viên',
                                  onTap: () => Get.find<MainWrapperViewModel>().requestAddFaceOnMembers(),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _buildQuickActionCard(
                                  context,
                                  Icons.history_outlined,
                                  'Xem Nhật Ký',
                                  onTap: () => Get.find<MainWrapperViewModel>().changePage(2),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
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
              ? [const Color(0xFF0D1424), const Color(0xFF0E1B2E)]
              : [const Color(0xFFF6F8FF), const Color(0xFFF7FBF7)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _buildGlowCircle(
              isDark ? const Color(0xFF1C2B52) : const Color(0xFFDDE7FF),
              160,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.6), color.withOpacity(0.05)],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, DashboardViewModel viewModel) {
    final total = viewModel.devices.length;
    final online = viewModel.devices.where(_isDeviceOnline).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Theo dõi trạng thái khóa trong thời gian thực.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatPill(context, icon: Icons.lock_outline, label: 'Tổng khóa', value: total.toString()),
              _buildStatPill(context, icon: Icons.wifi, label: 'Online', value: online.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }

  bool _isDeviceOnline(dynamic device) {
    final status = device['status']?.toString() ??
        ((device['is_online'] == true) ? 'ONLINE' : 'OFFLINE');
    return status.toUpperCase() == 'ONLINE';
  }

  // --- WIDGET THẺ KHÓA CỬA ---
  Widget _buildCompactLockCard({
    required BuildContext context, 
    required String deviceId, 
    required String title, 
    required String status, 
    required VoidCallback onUnlock,
    required DashboardViewModel viewModel,
    required bool isOwner,
  }) {
    // ÉP TOÀN BỘ VỀ CHỮ HOA ĐỂ SO SÁNH (Khắc phục lỗi phân biệt hoa/thường)
    final isOnline = status.toUpperCase() == 'ONLINE';
    
    // Màu nhấn: Online thì xanh nước biển (Primary), Offline thì Xám
    final accentColor = isOnline ? Theme.of(context).colorScheme.primary : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.12),
                border: Border.all(color: accentColor.withOpacity(0.4)),
              ),
              child: Icon(Icons.lock_outline, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              viewModel.cooldownTicker.value;
              final cooldownSeconds = viewModel.cooldownRemainingSeconds(deviceId);
              final isCooling = cooldownSeconds > 0;
              final isBusy = viewModel.isUnlockingDevice(deviceId);
              final canUnlock = isOnline && !isCooling && !isBusy;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleDeviceMenuAction(
                      context: context,
                      action: value,
                      deviceId: deviceId,
                      deviceName: title,
                      isOwner: isOwner,
                      viewModel: viewModel,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'share',
                        enabled: isOwner,
                        child: Text(isOwner ? 'Chia sẻ thiết bị' : 'Chia sẻ thiết bị (chỉ chủ)'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        enabled: isOwner,
                        child: Text(isOwner ? 'Xóa thiết bị' : 'Xóa thiết bị (chỉ chủ)'),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.outline),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: canUnlock ? onUnlock : null,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: canUnlock ? accentColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withOpacity(0.4)),
                      ),
                      child: isBusy
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isOnline ? accentColor : Colors.grey.shade400,
                                ),
                              ),
                            )
                          : isCooling
                              ? Center(
                                  child: Text(
                                    '${cooldownSeconds}s',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isOnline ? accentColor : Colors.grey.shade400,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.key,
                                  color: canUnlock ? Colors.white : accentColor,
                                  size: 24,
                                ),
                    ),
                  ),
                ],
              );
            })
          ],
        ),
      ),
    );
  }

  void _handleDeviceMenuAction({
    required BuildContext context,
    required String action,
    required String deviceId,
    required String deviceName,
    required bool isOwner,
    required DashboardViewModel viewModel,
  }) {
    if (action == 'share') {
      if (!isOwner) {
        Get.snackbar(
          'Không đủ quyền',
          'Chỉ chủ sở hữu mới được chia sẻ thiết bị này.',
          backgroundColor: const Color(0xFFBA1A1A),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        return;
      }

      if (deviceId.isEmpty) {
        Get.snackbar(
          'Thiếu thiết bị',
          'Không tìm thấy ID thiết bị để chia sẻ.',
          backgroundColor: const Color(0xFFBA1A1A),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        return;
      }

      Get.to(() => DeviceShareView(
            deviceId: deviceId,
            deviceName: deviceName,
            isOwner: isOwner,
          ));
    } else if (action == 'delete') {
      if (!isOwner) {
        Get.snackbar(
          'Không đủ quyền',
          'Chỉ chủ sở hữu mới được xóa thiết bị này.',
          backgroundColor: const Color(0xFFBA1A1A),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        return;
      }

      _confirmDeleteDevice(
        context: context,
        deviceId: deviceId,
        deviceName: deviceName,
        viewModel: viewModel,
      );
    }
  }

  Future<void> _confirmDeleteDevice({
    required BuildContext context,
    required String deviceId,
    required String deviceName,
    required DashboardViewModel viewModel,
  }) async {
    final theme = Theme.of(context);
    final nameLabel = deviceName.isNotEmpty ? '"$deviceName"' : 'thiết bị này';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thiết bị'),
        content: Text(
          'Bạn chắc chắn muốn xóa $nameLabel?\n\nNhật ký mở khóa vẫn được giữ lại để làm bằng chứng an ninh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy', style: TextStyle(color: theme.colorScheme.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await viewModel.deleteDevice(deviceId, deviceName: deviceName);
    }
  }

  // --- WIDGET NÚT TIỆN ÍCH ---
  Widget _buildQuickActionCard(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
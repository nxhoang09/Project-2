import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import '../viewmodels/face_profiles_viewmodel.dart';
import '../viewmodels/main_wrapper_viewmodel.dart';

class FaceProfilesView extends StatefulWidget {
  const FaceProfilesView({super.key});

  @override
  State<FaceProfilesView> createState() => _FaceProfilesViewState();
}

class _FaceProfilesViewState extends State<FaceProfilesView> {
  late final FaceProfilesViewModel _viewModel;
  late final MainWrapperViewModel _wrapperViewModel;
  Worker? _addFaceWorker;

  @override
  void initState() {
    super.initState();
    _viewModel = Get.put(FaceProfilesViewModel());
    _wrapperViewModel = Get.find<MainWrapperViewModel>();

    _addFaceWorker = everAll([
      _wrapperViewModel.selectedIndex,
      _wrapperViewModel.openAddFaceRequested,
    ], (_) {
      _maybeOpenAddFaceSheet();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeOpenAddFaceSheet();
    });
  }

  @override
  void dispose() {
    _addFaceWorker?.dispose();
    super.dispose();
  }

  void _maybeOpenAddFaceSheet() {
    if (!mounted) return;
    if (_wrapperViewModel.selectedIndex.value != 1) return;
    if (_wrapperViewModel.openAddFaceRequested.value != true) return;

    _wrapperViewModel.openAddFaceRequested.value = false;
    _showAddFaceSheet(context, _viewModel);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final contentWidth = ResponsiveUtils.getContentMaxWidth(context);
    final contentPadding = EdgeInsets.fromLTRB(
      pagePadding.left,
      pagePadding.top,
      pagePadding.right,
      pagePadding.bottom + 120,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D121C) : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(context, isDark)),
          RefreshIndicator(
            onRefresh: _viewModel.fetchProfiles,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: Padding(
                    padding: contentPadding,
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: [
                          _buildHeader(context, _viewModel, isDark),
                          const SizedBox(height: 24),
                          Obx(() {
                            if (_viewModel.isLoading.value) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (_viewModel.profiles.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    'Chưa có khuôn mặt nào. Hãy thêm mới!',
                                    style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: _viewModel.profiles.map((profile) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildProfileCard(context, _viewModel, profile),
                                );
                              }).toList(),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFaceSheet(context, _viewModel),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Thêm khuôn mặt', style: TextStyle(fontWeight: FontWeight.w600)),
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
              ? [const Color(0xFF0B1222), const Color(0xFF0E1A2F)]
              : [const Color(0xFFF4F7FF), const Color(0xFFF7FBF6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _buildGlowCircle(
              isDark ? const Color(0xFF1B2A52) : const Color(0xFFD9E6FF),
              180,
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: _buildGlowCircle(
              isDark ? const Color(0xFF112138) : const Color(0xFFDFF4E6),
              220,
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

  Widget _buildHeader(BuildContext context, FaceProfilesViewModel viewModel, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121826).withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.face_retouching_natural, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý Khuôn mặt',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kiểm soát và theo dõi quyền truy cập sinh trắc học của các thành viên trong gia đình.',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatPill(
                  context,
                  icon: Icons.face,
                  label: 'Khuôn mặt',
                  value: viewModel.profiles.length.toString(),
                ),
                _buildStatPill(
                  context,
                  icon: Icons.lock_outline,
                  label: 'Khóa',
                  value: viewModel.devices.length.toString(),
                ),
              ],
            );
          }),
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

  Widget _buildProfileCard(BuildContext context, FaceProfilesViewModel viewModel, dynamic profile) {
    final profileId = profile['id']?.toString() ?? '';
    final name = profile['name']?.toString() ?? 'Thành viên';
    final status = profile['status']?.toString() ?? 'SYNCED';
    final statusLabel = viewModel.getStatusLabel(status);
    final statusColor = viewModel.getStatusColor(status, context);
    final isPendingDelete = status.toUpperCase() == 'PENDING_DELETE';
    final deviceStatuses = (profile['device_statuses'] as List?) ?? [];
    final assignedDeviceIds = <String>{
      for (final item in deviceStatuses)
        if (item is Map && item['device_id'] != null) item['device_id'].toString(),
    };

    final deviceNameById = <String, String>{
      for (final device in viewModel.devices)
        if (device['id'] != null)
          device['id'].toString(): device['name']?.toString() ?? 'Khóa'
    };
    final deviceChips = <Widget>[];
    for (final item in deviceStatuses) {
      if (item is! Map) continue;
      final deviceId = item['device_id']?.toString() ?? '';
      if (deviceId.isEmpty) continue;
      final syncStatus = item['status']?.toString() ?? 'PENDING';
      final deviceName = deviceNameById[deviceId] ?? 'Khóa';
      final chipLabel = '$deviceName · ${viewModel.getStatusLabel(syncStatus)}';
      final chipColor = viewModel.getStatusColor(syncStatus, context);
      deviceChips.add(_buildStatusChip(chipLabel, chipColor, fontSize: 11));
    }

    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.25), statusColor.withOpacity(0.05)],
              ),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: isPendingDelete ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: statusColor,
                    color: isPendingDelete ? Theme.of(context).colorScheme.outline : null,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusChip(statusLabel, statusColor),
                if (deviceChips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: deviceChips,
                  ),
                ],
              ],
            ),
          ),
          Obx(() {
            final isDeleting = viewModel.deletingByProfile[profileId] == true;
            final isAssigning = viewModel.assigningByProfile[profileId] == true;
            final canSync = profileId.isNotEmpty && !isPendingDelete && !isAssigning;
            final canDelete = profileId.isNotEmpty && !isPendingDelete && !isDeleting;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: isAssigning
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.sync_alt,
                            color: canSync
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                          onPressed: canSync
                              ? () => _showAssignDialog(
                                    context,
                                    viewModel,
                                    profileId,
                                    name,
                                    assignedDeviceIds,
                                  )
                              : null,
                        ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: isDeleting
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.delete_outline,
                            color: canDelete
                                ? const Color(0xFFBA1A1A)
                                : Theme.of(context).colorScheme.outline,
                          ),
                          onPressed: canDelete
                              ? () => _confirmDelete(context, viewModel, profileId, name)
                              : null,
                        ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, {double fontSize = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: fontSize),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    FaceProfilesViewModel viewModel,
    String profileId,
    String profileName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa khuôn mặt'),
          content: Text('Bạn có chắc muốn xóa "$profileName" khỏi hệ thống?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                await viewModel.deleteProfile(profileId, profileName);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAssignDialog(
    BuildContext context,
    FaceProfilesViewModel viewModel,
    String profileId,
    String profileName,
    Set<String> assignedDeviceIds,
  ) {
    final availableDevices = viewModel.devices.where((device) {
      final deviceId = device['id']?.toString() ?? '';
      return deviceId.isNotEmpty && !assignedDeviceIds.contains(deviceId);
    }).toList();

    if (availableDevices.isEmpty) {
      Get.snackbar(
        'Không còn khóa',
        'Khuôn mặt này đã được đồng bộ lên tất cả khóa bạn đang sở hữu.',
        backgroundColor: const Color(0xFF00327D),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        maxWidth: 420,
      );
      return;
    }

    String selectedDeviceId = availableDevices.first['id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Đồng bộ sang khóa khác'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chọn khóa để đồng bộ khuôn mặt "$profileName".'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedDeviceId.isEmpty ? null : selectedDeviceId,
                    items: availableDevices.map((device) {
                      final name = device['name']?.toString() ?? 'Khóa';
                      final status = device['status']?.toString() ??
                          ((device['is_online'] == true) ? 'ONLINE' : 'OFFLINE');
                      final statusLabel = status == 'ONLINE' ? 'Online' : 'Offline';
                      return DropdownMenuItem<String>(
                        value: device['id']?.toString() ?? '',
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: status == 'ONLINE'
                                    ? const Color(0xFF006D37)
                                    : Theme.of(context).colorScheme.outline,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDeviceId = value ?? '';
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                Obx(() {
                  final isAssigning = viewModel.assigningByProfile[profileId] == true;
                  return ElevatedButton(
                    onPressed: isAssigning || selectedDeviceId.isEmpty
                        ? null
                        : () async {
                            await viewModel.assignProfileToDevice(
                              profileId: profileId,
                              deviceId: selectedDeviceId,
                              profileName: profileName,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: isAssigning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đồng bộ'),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddFaceSheet(BuildContext context, FaceProfilesViewModel viewModel) {
    if (viewModel.devices.isEmpty) {
      Get.snackbar(
        'Thiếu thiết bị',
        'Bạn chưa có khóa nào để đăng ký khuôn mặt.',
        backgroundColor: const Color(0xFFBA1A1A),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        maxWidth: 420,
      );
      return;
    }

    viewModel.resetForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đăng ký thành viên mới',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Tên thành viên', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: viewModel.nameController,
                decoration: InputDecoration(
                  hintText: 'Nhập tên...',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Chọn khóa đang đứng trước', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: viewModel.selectedDeviceId.value,
                    items: viewModel.devices.map((device) {
                      final name = device['name']?.toString() ?? 'Khóa';
                      final status = device['status']?.toString() ??
                          ((device['is_online'] == true) ? 'ONLINE' : 'OFFLINE');
                      final statusLabel = status == 'ONLINE' ? 'Online' : 'Offline';
                      return DropdownMenuItem<String>(
                        value: device['id']?.toString() ?? '',
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: status == 'ONLINE'
                                    ? const Color(0xFF006D37)
                                    : Theme.of(context).colorScheme.outline,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      viewModel.selectedDeviceId.value = value;
                    },
                  ),
                ),
              )),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(Icons.face, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Vui lòng đứng trước khóa cửa và nhìn thẳng vào camera',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: viewModel.isSubmitting.value
                      ? null
                      : () async {
                          final didStart = await viewModel.startEnrollment();
                          if (didStart) {
                            Navigator.of(context).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: viewModel.isSubmitting.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Bắt đầu đăng ký', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
            ],
          ),
          ),
        );
      },
    );
  }
}

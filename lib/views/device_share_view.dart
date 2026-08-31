import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import '../viewmodels/device_share_viewmodel.dart';

class DeviceShareView extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final bool isOwner;

  const DeviceShareView({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.isOwner,
  });

  @override
  State<DeviceShareView> createState() => _DeviceShareViewState();
}

class _DeviceShareViewState extends State<DeviceShareView> {
  late final DeviceShareViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Get.put(
      DeviceShareViewModel(
        deviceId: widget.deviceId,
        isOwner: widget.isOwner,
      ),
      tag: widget.deviceId,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<DeviceShareViewModel>(tag: widget.deviceId)) {
      Get.delete<DeviceShareViewModel>(tag: widget.deviceId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final contentWidth = ResponsiveUtils.getContentMaxWidth(context);
    final contentPadding = EdgeInsets.fromLTRB(
      pagePadding.left,
      pagePadding.top,
      pagePadding.right,
      pagePadding.bottom + 24,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        scrolledUnderElevation: 0,
        surfaceTintColor: theme.colorScheme.surface,
        title: Text(
          'Chia sẻ thiết bị',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(context, isDark)),
          RefreshIndicator(
            onRefresh: _viewModel.fetchShares,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeaderCard(context),
                          const SizedBox(height: 20),
                          if (!widget.isOwner)
                            _buildNoPermissionCard(context)
                          else
                            Obx(() {
                              if (_viewModel.isLoading.value) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              if (_viewModel.shares.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'Chưa chia sẻ thiết bị cho ai.',
                                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: _viewModel.shares.map((share) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildShareCard(context, share),
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
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _showAddShareSheet(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Thêm chia sẻ', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
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
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
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
            widget.deviceName.isEmpty ? 'Thiết bị' : widget.deviceName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Quản lý danh sách người được chia sẻ quyền sử dụng khóa.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildRoleChip(context, ShareRole.viewer),
              _buildRoleChip(context, ShareRole.admin),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, ShareRole role) {
    final label = _viewModel.roleLabel(role);
    final desc = _viewModel.roleDescription(role);
    final color = role == ShareRole.admin ? const Color(0xFF00327D) : const Color(0xFF006D37);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNoPermissionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chỉ chủ sở hữu mới có thể chia sẻ hoặc thu hồi quyền.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(BuildContext context, dynamic share) {
    final email = share['email']?.toString() ?? '';
    final role = _viewModel.parseRole(share['role']?.toString());
    final label = _viewModel.roleLabel(role);

    return InkWell(
      onTap: () => _showShareDetailDialog(context, email, role),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email.isEmpty ? 'Người dùng' : email,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text('Nhấn để xem quyền', style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDetailDialog(BuildContext context, String email, ShareRole role) {
    if (email.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(email),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quyền: ${_viewModel.roleLabel(role)}'),
              const SizedBox(height: 8),
              Text(_viewModel.roleDescription(role)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            if (widget.isOwner)
              Obx(() {
                final isRevoking = _viewModel.revokingByEmail[email] == true;
                return ElevatedButton(
                  onPressed: isRevoking
                      ? null
                      : () async {
                          await _viewModel.revokeShare(email);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
                  child: isRevoking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Hủy chia sẻ', style: TextStyle(color: Colors.white)),
                );
              }),
          ],
        );
      },
    );
  }

  void _showAddShareSheet(BuildContext context) {
    _viewModel.resetForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          // 1. Chỉ dùng viewInsets.bottom ở lớp ngoài cùng để đẩy BottomSheet lên
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          // 2. BẮT BUỘC THÊM SingleChildScrollView VÀO ĐÂY
          child: SingleChildScrollView(
            child: Padding(
              // 3. Đưa các padding gốc vào bên trong nội dung cuộn
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 24,
              ),
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
                    'Thêm chia sẻ mới',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Email người nhận', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _viewModel.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'email@example.com',
                      prefixIcon: const Icon(Icons.alternate_email),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Chọn quyền', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Obx(() {
                    return Column(
                      children: [
                        _buildRoleOption(context, ShareRole.viewer),
                        _buildRoleOption(context, ShareRole.admin),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() {
                      final isSubmitting = _viewModel.isSubmitting.value;
                      return ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final success = await _viewModel.addShare();
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(BuildContext context, ShareRole role) {
    final selected = _viewModel.selectedRole.value == role;
    final color = role == ShareRole.admin ? const Color(0xFF00327D) : const Color(0xFF006D37);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.1) : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? color : Colors.transparent),
      ),
      child: RadioListTile<ShareRole>(
        value: role,
        groupValue: _viewModel.selectedRole.value,
        onChanged: (value) {
          if (value == null) return;
          _viewModel.selectedRole.value = value;
        },
        activeColor: color,
        title: Text(_viewModel.roleLabel(role), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_viewModel.roleDescription(role)),
      ),
    );
  }
}

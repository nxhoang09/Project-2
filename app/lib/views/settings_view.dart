import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'profile_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(SettingsViewModel());
    final profileViewModel = Get.isRegistered<UserProfileViewModel>()
        ? Get.find<UserProfileViewModel>()
        : Get.put(UserProfileViewModel());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final contentWidth = ResponsiveUtils.getContentMaxWidth(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildBackground(context, isDark)),
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: pagePadding,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        context,
                        title: 'Tài khoản',
                        subtitle: 'Quản lý hồ sơ và thông tin đăng nhập.',
                      ),
                      const SizedBox(height: 12),
                      Obx(() => _buildAccountCard(context, profileViewModel)),
                      const SizedBox(height: 16),
                      _buildSectionTitle(
                        context,
                        title: 'Khác',
                        subtitle: 'Tuỳ chọn và hành động nhanh.',
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(context, viewModel),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cài đặt',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Tuỳ chỉnh trải nghiệm sử dụng SecureHome.',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ],
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

  Widget _buildAccountCard(BuildContext context, UserProfileViewModel viewModel) {
    final name = viewModel.fullName.value.trim();
    final avatarUrl = viewModel.avatarUrl.value.trim();
    final subtitle = viewModel.email.value.isNotEmpty
        ? viewModel.email.value
        : 'Xem và chỉnh sửa tài khoản';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return _buildCard(
      context,
      InkWell(
        onTap: () => Get.to(() => const ProfileView()),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            initials,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Người dùng',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(color: Theme.of(context).colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, SettingsViewModel viewModel) {
    return _buildCard(
      context,
      Column(
        children: [
          _buildRow(
            context,
            icon: Icons.logout,
            title: 'Đăng xuất',
            trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
            onTap: () => _confirmLogout(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, SettingsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                await viewModel.logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

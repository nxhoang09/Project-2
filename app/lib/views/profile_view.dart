import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import '../viewmodels/user_profile_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.isRegistered<UserProfileViewModel>()
        ? Get.find<UserProfileViewModel>()
        : Get.put(UserProfileViewModel());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final contentWidth = ResponsiveUtils.getContentMaxWidth(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(
          'Tài khoản',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ),
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
                      Obx(() => _buildHeader(context, viewModel)),
                      const SizedBox(height: 16),
                      _buildProfileForm(context, viewModel),
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

  Widget _buildBackground(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0C1425), const Color(0xFF0F1E33)]
              : [const Color(0xFFF6F8FF), const Color(0xFFF8FBF9)],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfileViewModel viewModel) {
    final name = viewModel.fullName.value.trim();
    final avatarUrl = viewModel.avatarUrl.value.trim();
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return _buildCard(
      context,
      Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                InkWell(
                  onTap: viewModel.isUploading.value ? null : viewModel.pickAndUploadAvatar,
                  borderRadius: BorderRadius.circular(40),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                initials,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      if (viewModel.isUploading.value)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      if (!viewModel.isUploading.value)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6),
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Người dùng',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        viewModel.email.value.isNotEmpty
                            ? viewModel.email.value
                            : 'Cập nhật thông tin tài khoản',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, UserProfileViewModel viewModel) {
    final fillColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6);

    return _buildCard(
      context,
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin tài khoản',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Cập nhật tên hiển thị của bạn.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: viewModel.fullNameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: viewModel.emailController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: viewModel.isSaving.value ? null : viewModel.saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: viewModel.isSaving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Lưu thay đổi'),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showChangePasswordDialog(context, viewModel),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Đổi mật khẩu'),
              ),
            ),
          ],
        ),
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

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    UserProfileViewModel viewModel,
  ) async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    var hideOld = true;
    var hideNew = true;
    var hideConfirm = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Đổi mật khẩu'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldController,
                    obscureText: hideOld,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      suffixIcon: IconButton(
                        icon: Icon(hideOld ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => hideOld = !hideOld),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: hideNew,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(hideNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => hideNew = !hideNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: hideConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(hideConfirm ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => hideConfirm = !hideConfirm),
                      ),
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
                  final isBusy = viewModel.isChangingPassword.value;
                  return ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final newPass = newController.text;
                            final confirmPass = confirmController.text;
                            if (newPass != confirmPass) {
                              Get.snackbar(
                                'Lỗi',
                                'Mật khẩu xác nhận không khớp.',
                                backgroundColor: const Color(0xFFBA1A1A),
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                                maxWidth: 420,
                                margin: const EdgeInsets.all(24),
                                borderRadius: 16,
                                icon: const Icon(Icons.error_outline, color: Colors.white),
                              );
                              return;
                            }
                            final success = await viewModel.changePassword(
                              oldPassword: oldController.text,
                              newPassword: newPass,
                            );
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Cập nhật'),
                  );
                }),
              ],
            );
          },
        );
      },
    );

    oldController.dispose();
    newController.dispose();
    confirmController.dispose();
  }
}

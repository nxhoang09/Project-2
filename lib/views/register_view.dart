import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodels/register_viewmodel.dart';
import '../utils/responsive_utils.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(RegisterViewModel());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final cardWidth = ResponsiveUtils.getLoginCardWidth(context);
    final cardPadding = ResponsiveUtils.isMobile(context) ? 24.0 : 40.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: _buildAuthBackground(context, isDark)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: pagePadding,
                child: Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(22.0),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.person_add_alt_1_outlined, color: Theme.of(context).colorScheme.primary, size: 26),
                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tạo tài khoản',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      'Tham gia hệ sinh thái SecureHome',
                                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.isMobile(context) ? 24 : 32),

                          _buildLabel(context, 'Họ và tên'),
                          TextField(
                            controller: viewModel.nameController,
                            decoration: _inputDecoration(context, 'Nguyễn Văn A', Icons.person_outline),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(context, 'Email / Số điện thoại'),
                          TextField(
                            controller: viewModel.emailController,
                            decoration: _inputDecoration(context, 'example@gmail.com', Icons.email_outlined),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(context, 'Mật khẩu'),
                          Obx(() => TextField(
                                controller: viewModel.passwordController,
                                obscureText: viewModel.isPasswordHidden.value,
                                decoration: _inputDecoration(context, '••••••••', Icons.lock_outline).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(viewModel.isPasswordHidden.value ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: viewModel.togglePassword,
                                  ),
                                ),
                              )),
                          const SizedBox(height: 16),

                          _buildLabel(context, 'Xác nhận mật khẩu'),
                          Obx(() => TextField(
                                controller: viewModel.confirmPasswordController,
                                obscureText: viewModel.isConfirmPasswordHidden.value,
                                decoration: _inputDecoration(context, '••••••••', Icons.verified_user_outlined).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(viewModel.isConfirmPasswordHidden.value ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: viewModel.toggleConfirmPassword,
                                  ),
                                ),
                              )),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Obx(() => ElevatedButton(
                                  onPressed: viewModel.isLoading.value ? null : viewModel.register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: viewModel.isLoading.value
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                                      : const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                )),
                          ),
                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () => Get.back(),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Đã có tài khoản? ',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  children: [
                                    TextSpan(
                                      text: 'Đăng nhập',
                                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildAuthBackground(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0B1222), const Color(0xFF0F1D33)]
              : [const Color(0xFFF5F8FF), const Color(0xFFF7FBF9)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _buildGlowCircle(
              isDark ? const Color(0xFF1B2A52) : const Color(0xFFDDE8FF),
              180,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _buildGlowCircle(
              isDark ? const Color(0xFF102137) : const Color(0xFFDFF3E6),
              200,
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

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.outline),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
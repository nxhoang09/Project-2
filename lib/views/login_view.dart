import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lock_app/views/register_view.dart';
import 'forgot_password_email_view.dart';
import '../viewmodels/login_viewmodel.dart';
import '../utils/responsive_utils.dart'; 

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(LoginViewModel());
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
                                child: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SecureHome',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'Chào mừng trở lại',
                                    style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.isMobile(context) ? 24 : 32),

                          _buildLabel(context, 'Email'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: viewModel.emailController,
                            decoration: _inputDecoration(context, 'Nhập email', Icons.person_outline),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel(context, 'Mật khẩu'),
                          const SizedBox(height: 8),
                          Obx(() => TextField(
                                controller: viewModel.passwordController,
                                obscureText: viewModel.isPasswordHidden.value,
                                decoration: _inputDecoration(context, '••••••••', Icons.key_outlined).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      viewModel.isPasswordHidden.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    onPressed: viewModel.togglePasswordVisibility,
                                  ),
                                ),
                                onSubmitted: (_) => viewModel.login(),
                              )),
                          SizedBox(height: ResponsiveUtils.isMobile(context) ? 24 : 32),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Obx(() => ElevatedButton(
                                  onPressed: viewModel.isLoading.value ? null : viewModel.login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: viewModel.isLoading.value
                                      ? const SizedBox(
                                          width: 24, height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                )),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                TextButton(
                                  onPressed: () => Get.to(() => const ForgotPasswordEmailView()),
                                  child: Text('Quên mật khẩu?', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                ),
                                TextButton(
                                  onPressed: () => Get.to(() => const RegisterView()),
                                  child: Text('Đăng ký tài khoản mới', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                                ),
                              ],
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.outline),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
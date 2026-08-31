import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import '../viewmodels/forgot_password_reset_viewmodel.dart';

class ForgotPasswordResetView extends StatefulWidget {
  final String email;
  final String otp;

  const ForgotPasswordResetView({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ForgotPasswordResetView> createState() => _ForgotPasswordResetViewState();
}

class _ForgotPasswordResetViewState extends State<ForgotPasswordResetView> {
  late final ForgotPasswordResetViewModel _viewModel;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = 'forgot_reset_${widget.email}_${widget.otp}';
    _viewModel = Get.put(
      ForgotPasswordResetViewModel(email: widget.email, otp: widget.otp),
      tag: _tag,
      permanent: true,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ForgotPasswordResetViewModel>(tag: _tag)) {
      Get.delete<ForgotPasswordResetViewModel>(tag: _tag, force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pagePadding = ResponsiveUtils.getPagePadding(context);
    final cardWidth = ResponsiveUtils.getLoginCardWidth(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        scrolledUnderElevation: 0,
        surfaceTintColor: theme.colorScheme.surface,
        title: Text(
          'Đặt mật khẩu mới',
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
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: pagePadding,
                child: SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tạo mật khẩu mới',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mật khẩu mới phải có ít nhất 6 ký tự.',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 20),
                        Text('Mật khẩu mới', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Obx(() => TextField(
                              controller: _viewModel.newPasswordController,
                              obscureText: _viewModel.isPasswordHidden.value,
                              decoration: _inputDecoration(context, 'Nhập mật khẩu mới', Icons.key_outlined).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _viewModel.isPasswordHidden.value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: theme.colorScheme.outline,
                                  ),
                                  onPressed: _viewModel.togglePasswordVisibility,
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                        Text('Xác nhận mật khẩu', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Obx(() => TextField(
                              controller: _viewModel.confirmPasswordController,
                              obscureText: _viewModel.isConfirmHidden.value,
                              decoration: _inputDecoration(context, 'Nhập lại mật khẩu', Icons.key_outlined).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _viewModel.isConfirmHidden.value
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: theme.colorScheme.outline,
                                  ),
                                  onPressed: _viewModel.toggleConfirmVisibility,
                                ),
                              ),
                            )),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Obx(() => ElevatedButton(
                                onPressed: _viewModel.isSubmitting.value ? null : _viewModel.submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: _viewModel.isSubmitting.value
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Đổi mật khẩu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              )),
                        ),
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

  BoxDecoration _cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.colorScheme.outline),
      prefixIcon: Icon(icon, color: theme.colorScheme.outline),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}

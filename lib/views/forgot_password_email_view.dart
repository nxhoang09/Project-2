import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import '../viewmodels/forgot_password_email_viewmodel.dart';

class ForgotPasswordEmailView extends StatefulWidget {
  const ForgotPasswordEmailView({super.key});

  @override
  State<ForgotPasswordEmailView> createState() => _ForgotPasswordEmailViewState();
}

class _ForgotPasswordEmailViewState extends State<ForgotPasswordEmailView> {
  late final ForgotPasswordEmailViewModel _viewModel;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = 'forgot_email';
    _viewModel = Get.put(
      ForgotPasswordEmailViewModel(),
      tag: _tag,
      permanent: true,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ForgotPasswordEmailViewModel>(tag: _tag)) {
      Get.delete<ForgotPasswordEmailViewModel>(tag: _tag, force: true);
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
          'Quên mật khẩu',
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
                          'Nhập Email',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chúng tôi sẽ gửi mã OTP để bạn đặt lại mật khẩu.',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 20),
                        Text('Email', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _viewModel.emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _viewModel.submit(),
                          decoration: _inputDecoration(context, 'Nhập email', Icons.person_outline),
                        ),
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
                                    : const Text('Gửi mã OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

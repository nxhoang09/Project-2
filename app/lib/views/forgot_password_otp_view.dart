import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../utils/responsive_utils.dart';
import '../viewmodels/forgot_password_otp_viewmodel.dart';

class ForgotPasswordOtpView extends StatefulWidget {
  final String email;

  const ForgotPasswordOtpView({super.key, required this.email});

  @override
  State<ForgotPasswordOtpView> createState() => _ForgotPasswordOtpViewState();
}

class _ForgotPasswordOtpViewState extends State<ForgotPasswordOtpView> {
  late final ForgotPasswordOtpViewModel _viewModel;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = 'forgot_otp_${widget.email}';
    _viewModel = Get.put(
      ForgotPasswordOtpViewModel(email: widget.email),
      tag: _tag,
      permanent: true,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ForgotPasswordOtpViewModel>(tag: _tag)) {
      Get.delete<ForgotPasswordOtpViewModel>(tag: _tag, force: true);
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
          'Nhập mã OTP',
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
                          'Xác thực Email',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhập mã OTP gồm 6 số đã gửi tới:',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20),
                        PinCodeTextField(
                          appContext: context,
                          controller: _viewModel.otpController,
                          length: 6,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          animationType: AnimationType.fade,
                          enableActiveFill: true,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            activeColor: theme.colorScheme.primary,
                            selectedColor: theme.colorScheme.primary,
                            inactiveColor: theme.colorScheme.outlineVariant,
                            activeFillColor: theme.colorScheme.surfaceVariant,
                            selectedFillColor: theme.colorScheme.surfaceVariant,
                            inactiveFillColor: theme.colorScheme.surfaceVariant,
                          ),
                          onChanged: (value) => _viewModel.otpValue.value = value,
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          final remaining = _formatDuration(_viewModel.remainingSeconds.value);
                          final isExpired = _viewModel.isExpired;
                          return Text(
                            isExpired ? 'Mã OTP đã hết hạn.' : 'Mã hết hạn sau $remaining',
                            style: TextStyle(
                              color: isExpired
                                  ? const Color(0xFFBA1A1A)
                                  : theme.colorScheme.outline,
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Obx(() => ElevatedButton(
                                onPressed: _viewModel.canContinue ? _viewModel.goNext : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: const Text('Tiếp tục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
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
}

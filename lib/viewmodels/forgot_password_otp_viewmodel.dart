import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/forgot_password_reset_view.dart';

class ForgotPasswordOtpViewModel extends GetxController {
  ForgotPasswordOtpViewModel({required this.email});

  final String email;
  final otpController = TextEditingController();
  final otpValue = ''.obs;
  final remainingSeconds = 600.obs;
  Timer? _timer;
  bool _didDispose = false;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value <= 0) {
        _timer?.cancel();
      } else {
        remainingSeconds.value--;
      }
    });
  }

  bool get isExpired => remainingSeconds.value <= 0;

  bool get canContinue => !isExpired && otpValue.value.length == 6;

  void goNext() {
    if (!canContinue) return;
    Get.to(() => ForgotPasswordResetView(email: email, otp: otpValue.value));
  }

  @override
  void onClose() {
    if (_didDispose) return;
    _didDispose = true;
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../views/forgot_password_otp_view.dart';

class ForgotPasswordEmailViewModel extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final emailController = TextEditingController();
  var isSubmitting = false.obs;
  bool _didDispose = false;

  Future<void> submit() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError('Vui lòng nhập Email để tiếp tục.');
      return;
    }

    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final response = await _authService.forgotPassword(email);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.data['message'] ?? 'Đã gửi mã OTP qua email.';
        Get.snackbar(
          'Thành công',
          message,
          backgroundColor: const Color(0xFF006D37),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        Get.to(() => ForgotPasswordOtpView(email: email));
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể gửi mã OTP.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Lỗi',
      message,
      backgroundColor: const Color(0xFFBA1A1A),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      maxWidth: 420,
      margin: const EdgeInsets.all(24),
      borderRadius: 16,
    );
  }

  @override
  void onClose() {
    if (_didDispose) return;
    _didDispose = true;
    emailController.dispose();
    super.onClose();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../views/login_view.dart';

class ForgotPasswordResetViewModel extends GetxController {
  ForgotPasswordResetViewModel({required this.email, required this.otp});

  final String email;
  final String otp;
  final AuthService _authService = Get.find<AuthService>();

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isSubmitting = false.obs;
  var isPasswordHidden = true.obs;
  var isConfirmHidden = true.obs;
  bool _didDispose = false;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmVisibility() {
    isConfirmHidden.value = !isConfirmHidden.value;
  }

  Future<void> submit() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showError('Vui lòng nhập đầy đủ mật khẩu mới.');
      return;
    }
    if (newPassword.length < 6) {
      _showError('Mật khẩu mới phải có ít nhất 6 ký tự.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('Mật khẩu xác nhận không khớp.');
      return;
    }

    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      final response = await _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.data['message'] ?? 'Đổi mật khẩu thành công.';
        Get.snackbar(
          'Thành công',
          message,
          backgroundColor: const Color(0xFF006D37),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        Get.offAll(() => const LoginView());
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể đổi mật khẩu.');
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
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

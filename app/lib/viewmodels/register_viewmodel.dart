import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class RegisterViewModel extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordHidden = true.obs;
  var isConfirmPasswordHidden = true.obs;
  var isLoading = false.obs;

  final AuthService _authService = Get.find<AuthService>();

  void togglePassword() => isPasswordHidden.value = !isPasswordHidden.value;
  void toggleConfirmPassword() => isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;

  Future<void> register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String pass = passwordController.text;
    String confirmPass = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin.');
      return;
    }
    if (!GetUtils.isEmail(email)) {
      _showError('Email không đúng định dạng.');
      return;
    }
    if (pass != confirmPass) {
      _showError('Mật khẩu xác nhận không khớp.');
      return;
    }
    if (pass.length < 6) {
      _showError('Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }

    // 2. Gọi API NestJS
    try {
      isLoading.value = true;
      final response = await _authService.register(name, email, pass);

      if (response.statusCode == 200 || response.statusCode == 201) {
        String serverMessage = response.data['message'] ?? 'Tạo tài khoản thành công! Vui lòng đăng nhập.';
        Get.back();
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Thành công', 
            serverMessage, 
            backgroundColor: const Color(0xFF006D37), // Emerald Green
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            maxWidth: 400,
            margin: const EdgeInsets.all(24),
          );
        });
      } else {
        final dynamic message = response.data is Map ? response.data['message'] : null;
        _showError(message?.toString() ?? 'Đăng ký thất bại');
      }
    } on DioException catch (e) {
      String errorMessage = e.response?.data['message'] ?? 'Đăng ký thất bại';
      if (e.response?.data['message'] is List) {
        errorMessage = e.response?.data['message'][0]; 
      }
      _showError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

   void _showError(String message) {
    Get.snackbar(
      'Lỗi', 
      message,
      backgroundColor: const Color(0xFFBA1A1A), 
      colorText: Colors.white,
      snackPosition:SnackPosition.BOTTOM,
      maxWidth: 400, 
      margin: const EdgeInsets.all(24),
      borderRadius: 16, 
      icon: const Icon(Icons.error_outline, color: Colors.white),
      animationDuration: const Duration(milliseconds: 400),
    );
  }
}
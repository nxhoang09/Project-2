import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_lock_app/services/auth_service.dart';
import 'package:smart_lock_app/views/main_wrapper_view.dart';

class LoginViewModel extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordHidden = true.obs;
  var isLoading = false.obs;

  final AuthService _authService = Get.find<AuthService>();

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void clearFields() {
    emailController.clear();
    passwordController.clear();
    isPasswordHidden.value = true;
    isLoading.value = false;
  }

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ Email và Mật khẩu.');
      return;
    }

    try {
      isLoading.value = true; 
      final response = await _authService.login(email, password);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        await prefs.setString('user_id', data['user']['id']);
        await prefs.setString('user_name', data['user']['name'] ?? 'User');
        await prefs.setString('user_email', data['user']['email'] ?? '');
        await prefs.setString('avatar_url', data['user']['avatar_url'] ?? '');

        Get.snackbar('Thành công', 'Đăng nhập thành công!', backgroundColor: const Color(0xFF006D37), colorText: Colors.white, maxWidth: 400);
        Get.offAll(() => const MainWrapperView());
      }
    } on DioException catch (e) {
      String errorMessage = 'Không thể kết nối đến máy chủ.';
      
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 'Đăng nhập thất bại (Mã: ${e.response?.statusCode})';
      }
      
      _showError(errorMessage);
    } catch (e) {
      _showError('Đã xảy ra lỗi hệ thống: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Hàm tiện ích để hiển thị lỗi cho code gọn
  void _showError(String message) {
    Get.snackbar(
      'Lỗi xác thực', 
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

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
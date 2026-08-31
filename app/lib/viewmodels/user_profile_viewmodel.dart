import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class UserProfileViewModel extends GetxController {
  final UserService _userService = Get.find<UserService>();
  final AuthService _authService = Get.find<AuthService>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  final fullName = ''.obs;
  final email = ''.obs;
  final avatarUrl = ''.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploading = false.obs;
  final isChangingPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCachedProfile();
    fetchProfile();
  }

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    fullName.value = prefs.getString('user_name') ?? '';
    email.value = prefs.getString('user_email') ?? '';
    avatarUrl.value = prefs.getString('avatar_url') ?? '';
    fullNameController.text = fullName.value;
    emailController.text = email.value;
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final response = await _userService.getProfile();
      if (response.statusCode == 200) {
        _applyProfile(response.data);
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể tải thông tin tài khoản.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile() async {
    final name = fullNameController.text.trim();
    if (name.isEmpty) {
      _showError('Vui lòng nhập họ và tên.');
      return;
    }

    try {
      isSaving.value = true;
      final response = await _userService.updateProfile(fullName: name);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _applyProfile(response.data);
        _showSuccess('Thành công', 'Đã cập nhật thông tin tài khoản.');
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể cập nhật thông tin.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;

    try {
      isUploading.value = true;
      final response = await _userService.uploadAvatar(picked.path);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _applyProfile(response.data);
        _showSuccess('Thành công', 'Ảnh đại diện đã được cập nhật.');
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể cập nhật ảnh đại diện.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      _showError('Vui lòng nhập đầy đủ mật khẩu.');
      return false;
    }
    if (newPassword.length < 6) {
      _showError('Mật khẩu mới phải có ít nhất 6 ký tự.');
      return false;
    }

    try {
      isChangingPassword.value = true;
      final response = await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccess('Thành công', response.data['message'] ?? 'Đổi mật khẩu thành công.');
        return true;
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể đổi mật khẩu.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isChangingPassword.value = false;
    }
    return false;
  }

  void _applyProfile(dynamic data) async {
    if (data is! Map) return;
    fullName.value = data['full_name']?.toString() ?? data['name']?.toString() ?? fullName.value;
    email.value = data['email']?.toString() ?? email.value;
    avatarUrl.value = data['avatar_url']?.toString() ?? '';
    fullNameController.text = fullName.value;
    emailController.text = email.value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', fullName.value);
    await prefs.setString('user_email', email.value);
    await prefs.setString('avatar_url', avatarUrl.value);
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
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFF006D37),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      maxWidth: 420,
      margin: const EdgeInsets.all(24),
      borderRadius: 16,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}

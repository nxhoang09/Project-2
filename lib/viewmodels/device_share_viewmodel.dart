import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/device_service.dart';

enum ShareRole { admin, viewer }

class DeviceShareViewModel extends GetxController {
  DeviceShareViewModel({
    required this.deviceId,
    required this.isOwner,
  });

  final String deviceId;
  final bool isOwner;

  final DeviceService _deviceService = Get.find<DeviceService>();

  var shares = [].obs;
  var isLoading = true.obs;
  var isSubmitting = false.obs;
  final revokingByEmail = <String, bool>{}.obs;

  final emailController = TextEditingController();
  final selectedRole = ShareRole.viewer.obs;

  @override
  void onInit() {
    super.onInit();
    if (deviceId.isNotEmpty && isOwner) {
      fetchShares();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> fetchShares() async {
    if (!isOwner) {
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      final response = await _deviceService.getDeviceShares(deviceId);
      if (response.statusCode == 200) {
        shares.assignAll(response.data ?? []);
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể tải danh sách chia sẻ.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addShare() async {
    if (!isOwner) return false;

    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError('Vui lòng nhập email người nhận.');
      return false;
    }

    if (isSubmitting.value) return false;

    isSubmitting.value = true;
    try {
      final response = await _deviceService.shareDevice(
        deviceId: deviceId,
        email: email,
        role: roleValue(selectedRole.value),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.data['message'] ?? 'Đã chia sẻ thiết bị.';
        Get.snackbar(
          'Thành công',
          message,
          backgroundColor: const Color(0xFF00327D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        await fetchShares();
        return true;
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể chia sẻ thiết bị.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isSubmitting.value = false;
    }
    return false;
  }

  Future<void> revokeShare(String email) async {
    if (!isOwner || email.isEmpty) return;
    if (revokingByEmail[email] == true) return;

    revokingByEmail[email] = true;
    try {
      final response = await _deviceService.revokeShare(deviceId: deviceId, email: email);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.data['message'] ?? 'Đã hủy chia sẻ.';
        Get.snackbar(
          'Đã thu hồi',
          message,
          backgroundColor: const Color(0xFF00327D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        await fetchShares();
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể hủy chia sẻ.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      revokingByEmail[email] = false;
    }
  }

  void resetForm() {
    emailController.clear();
    selectedRole.value = ShareRole.viewer;
  }

  ShareRole parseRole(String? role) {
    if (role == 'admin') return ShareRole.admin;
    return ShareRole.viewer;
  }

  String roleValue(ShareRole role) {
    return role == ShareRole.admin ? 'admin' : 'viewer';
  }

  String roleLabel(ShareRole role) {
    return role == ShareRole.admin ? 'Quản lý' : 'Xem';
  }

  String roleDescription(ShareRole role) {
    if (role == ShareRole.admin) {
      return 'Mở khóa, xem log và quản lý khuôn mặt.';
    }
    return 'Mở khóa và xem log.';
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
    emailController.dispose();
    super.onClose();
  }
}

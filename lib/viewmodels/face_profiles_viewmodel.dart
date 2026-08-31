import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/face_profile_service.dart';
import '../services/device_event_service.dart';

class FaceProfilesViewModel extends GetxController {
  final FaceProfileService _faceProfileService = Get.find<FaceProfileService>();
  final DeviceEventService _deviceEventService = Get.find<DeviceEventService>();

  var profiles = [].obs;
  var devices = [].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  final deletingByProfile = <String, bool>{}.obs;
  final assigningByProfile = <String, bool>{}.obs;

  final nameController = TextEditingController();
  var selectedDeviceId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _connectSocket();
    fetchProfiles();
  }

  Future<void> fetchProfiles() async {
    try {
      isLoading.value = true;
      final response = await _faceProfileService.getMyFaceProfiles();
      if (response.statusCode == 200) {
        profiles.assignAll(response.data['profiles'] ?? []);
        devices.assignAll(response.data['devices'] ?? []);
        if (selectedDeviceId.value.isEmpty && devices.isNotEmpty) {
          selectedDeviceId.value = devices.first['id']?.toString() ?? '';
        }
        _joinDeviceRooms();
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể tải danh sách khuôn mặt.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _connectSocket() {
    _deviceEventService.initSocket(onStatusChanged: _handleStatusChanged);
  }

  void _joinDeviceRooms() {
    for (final device in devices) {
      final deviceId = device['id']?.toString() ?? '';
      if (deviceId.isNotEmpty) {
        _deviceEventService.joinDeviceRoom(deviceId);
      }
    }
  }

  void _handleStatusChanged(dynamic data) {
    if (data is! Map) return;
    final deviceId = data['deviceId']?.toString() ?? '';
    final status = data['status']?.toString() ?? '';
    if (deviceId.isEmpty || status.isEmpty) return;

    final index = devices.indexWhere((device) => device['id']?.toString() == deviceId);
    if (index == -1) return;

    devices[index]['status'] = status;
    devices.refresh();
  }

  Future<bool> startEnrollment() async {
    final name = nameController.text.trim();
    final deviceId = selectedDeviceId.value;

    if (name.isEmpty) {
      _showError('Vui lòng nhập tên thành viên.');
      return false;
    }
    if (deviceId.isEmpty) {
      _showError('Vui lòng chọn khóa.');
      return false;
    }

    dynamic selectedDevice;
    for (final device in devices) {
      if (device['id']?.toString() == deviceId) {
        selectedDevice = device;
        break;
      }
    }
    final deviceStatus = selectedDevice?['status']?.toString() ??
        ((selectedDevice?['is_online'] == true) ? 'ONLINE' : 'OFFLINE');
    if (deviceStatus == 'OFFLINE') {
      _showError('Khóa đang Offline. Vui lòng bật khóa trước khi đăng ký.');
      return false;
    }

    var isSuccess = false;
    try {
      isSubmitting.value = true;
      final response = await _faceProfileService.enrollFace(
        deviceId: deviceId,
        name: name,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        isSuccess = true;
        final message = response.data['message'] ?? 'Đã gửi yêu cầu đăng ký.';
        Get.snackbar(
          'Đang xử lý',
          message,
          backgroundColor: const Color(0xFF00327D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        await fetchProfiles();
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể gửi yêu cầu đăng ký.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      isSubmitting.value = false;
    }
    return isSuccess;
  }

  Future<void> deleteProfile(String profileId, String profileName) async {
    if (profileId.isEmpty) return;
    if (deletingByProfile[profileId] == true) return;

    deletingByProfile[profileId] = true;
    try {
      final response = await _faceProfileService.deleteFace(profileId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.data['message'] ?? 'Đã gửi yêu cầu xóa khuôn mặt "$profileName".';
        Get.snackbar(
          'Đang xử lý',
          message,
          backgroundColor: const Color(0xFF00327D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        await fetchProfiles();
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể xóa khuôn mặt.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      deletingByProfile[profileId] = false;
    }
  }

  Future<void> assignProfileToDevice({
    required String profileId,
    required String deviceId,
    required String profileName,
  }) async {
    if (profileId.isEmpty || deviceId.isEmpty) return;
    if (assigningByProfile[profileId] == true) return;

    dynamic targetDevice;
    for (final device in devices) {
      if (device['id']?.toString() == deviceId) {
        targetDevice = device;
        break;
      }
    }
    final deviceStatus = targetDevice?['status']?.toString() ??
        ((targetDevice?['is_online'] == true) ? 'ONLINE' : 'OFFLINE');
    if (deviceStatus == 'OFFLINE') {
      _showError('Khóa đang Offline. Vui lòng bật khóa trước khi đồng bộ.');
      return;
    }

    assigningByProfile[profileId] = true;
    try {
      final response = await _faceProfileService.assignFaceToDevice(profileId, deviceId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.data['message'] ?? 'Đã gửi yêu cầu đồng bộ "$profileName".';
        Get.snackbar(
          'Đang xử lý',
          message,
          backgroundColor: const Color(0xFF00327D),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          maxWidth: 420,
        );
        await fetchProfiles();
      }
    } on DioException catch (e) {
      _showError(e.response?.data['message'] ?? 'Không thể đồng bộ khuôn mặt.');
    } catch (e) {
      _showError('Đã xảy ra lỗi: $e');
    } finally {
      assigningByProfile[profileId] = false;
    }
  }

  void resetForm() {
    nameController.clear();
    if (devices.isNotEmpty) {
      selectedDeviceId.value = devices.first['id']?.toString() ?? '';
    }
  }

  String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING_DELETE':
        return 'Đang chờ xóa...';
      case 'PENDING':
        return 'Đang đồng bộ...';
      case 'FAILED':
        return 'Lỗi đồng bộ';
      case 'SYNCED':
      default:
        return 'Đã đồng bộ';
    }
  }

  Color getStatusColor(String status, BuildContext context) {
    switch (status.toUpperCase()) {
      case 'PENDING_DELETE':
        return const Color(0xFFBA1A1A);
      case 'PENDING':
        return Theme.of(context).colorScheme.primary;
      case 'FAILED':
        return const Color(0xFFBA1A1A);
      case 'SYNCED':
      default:
        return const Color(0xFF006D37);
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
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }
}

import 'dart:async';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/device_event_service.dart';
import '../services/device_service.dart';
import 'activity_viewmodel.dart';

class DashboardViewModel extends GetxController {
  final DeviceService _deviceService = Get.find<DeviceService>();
  final DeviceEventService _deviceEventService = Get.find<DeviceEventService>();
  var devices = [].obs;
  var isLoading = true.obs;
  final unlockCooldownSeconds = 5;
  final cooldownEndByDevice = <String, DateTime>{}.obs;
  final cooldownTicker = 0.obs;
  final unlockingByDevice = <String, bool>{}.obs;
  Timer? _cooldownTimer;

  var isUnlocking = false.obs; 
  @override
  void onInit() {
    super.onInit();
    _connectSocket();
    fetchDevices();
  }

  void _connectSocket() {
    _deviceEventService.initSocket(
      onUnlockResult: _handleUnlockResult,
      onStatusChanged: _handleStatusChanged,
    );
  }

  void _joinDeviceRooms() {
    for (final device in devices) {
      final deviceId = device['id'];
      if (deviceId is String && deviceId.isNotEmpty) {
        _deviceEventService.joinDeviceRoom(deviceId);
      }
    }
  }

  Future<void> fetchDevices({bool showLoadingIndicator = true}) async {
    try {
      if (showLoadingIndicator) {
        isLoading.value = true;
      }
      final response = await _deviceService.getMyDevices();
      
      if (response.statusCode == 200) {
        devices.assignAll(response.data);
        _joinDeviceRooms();
      }
    } on DioException catch (e) {
      // Thông báo khi kéo để reload mà vẫn mất mạng
      if (!showLoadingIndicator) {
        Get.snackbar(
          'Lỗi kết nối', 
          'Không thể làm mới dữ liệu. Vui lòng kiểm tra lại mạng!',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (showLoadingIndicator) {
        isLoading.value = false;
      }
    }
  }

  Future<void> deleteDevice(String deviceId, {String? deviceName}) async {
    if (deviceId.isEmpty) return;

    try {
      final response = await _deviceService.deleteDevice(deviceId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        devices.removeWhere((device) => device['id'] == deviceId);
        devices.refresh();

        cooldownEndByDevice.remove(deviceId);
        unlockingByDevice.remove(deviceId);

        if (Get.isRegistered<ActivityViewModel>()) {
          Get.find<ActivityViewModel>().handleDeviceDeleted(
            deviceId,
            deviceName: deviceName ?? '',
          );
        }

        final label = (deviceName != null && deviceName.isNotEmpty) ? deviceName : 'Khóa';
        Get.snackbar('Đã xóa thiết bị', '$label đã được xóa khỏi ứng dụng.');
      } else {
        Get.snackbar('Thất bại', 'Không thể xóa thiết bị. Vui lòng thử lại.');
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Lỗi không xác định';
      Get.snackbar('Thất bại', msg, backgroundColor: Get.theme.colorScheme.error);
    }
  }

  bool isUnlockingDevice(String deviceId) {
    return unlockingByDevice[deviceId] == true;
  }

  bool isCooldownActive(String deviceId) {
    final endAt = cooldownEndByDevice[deviceId];
    if (endAt == null) return false;
    return endAt.isAfter(DateTime.now());
  }

  int cooldownRemainingSeconds(String deviceId) {
    final endAt = cooldownEndByDevice[deviceId];
    if (endAt == null) return 0;
    final remaining = endAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _startCooldown(String deviceId) {
    cooldownEndByDevice[deviceId] = DateTime.now().add(
      Duration(seconds: unlockCooldownSeconds),
    );
    _ensureCooldownTimer();
  }

  void _ensureCooldownTimer() {
    if (_cooldownTimer != null) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      cooldownTicker.value++;
      _cleanupExpiredCooldowns();
      if (cooldownEndByDevice.isEmpty) {
        _cooldownTimer?.cancel();
        _cooldownTimer = null;
      }
    });
  }

  void _cleanupExpiredCooldowns() {
    final now = DateTime.now();
    final expired = cooldownEndByDevice.entries
        .where((entry) => !entry.value.isAfter(now))
        .map((entry) => entry.key)
        .toList();
    for (final deviceId in expired) {
      cooldownEndByDevice.remove(deviceId);
    }
  }

  void _handleUnlockResult(dynamic data) {
    if (data is! Map) return;

    final status = data['status'];
    final deviceId = data['device_id'];
    final reason = data['reason'];

    String? deviceName;
    if (deviceId is String) {
      for (final device in devices) {
        if (device['id'] == deviceId) {
          deviceName = device['name'];
          break;
        }
      }
    }

    final label = deviceName ?? 'Khóa';
    if (status == 'success') {
      Get.snackbar('Mở khóa', '$label mở cửa thành công!');
    } else if (status == 'failed') {
      final extra = reason is String && reason.isNotEmpty ? ': $reason' : '';
      Get.snackbar('Thất bại', '$label mở cửa thất bại$extra', backgroundColor: Get.theme.colorScheme.error);
    }
  }
  void _handleStatusChanged(dynamic data) {
    if (data is! Map) return;
    
    final deviceId = data['deviceId'];
    final status = data['status'];

    int index = devices.indexWhere((d) => d['id'] == deviceId);

    if (index != -1) {
      devices[index]['status'] = status;
      devices.refresh(); 
    }
  }

  Future<void> unlock(String deviceId) async {
    bool didStartUnlock = false;
    try {
      if (isCooldownActive(deviceId)) {
        final waitSeconds = cooldownRemainingSeconds(deviceId);
        Get.snackbar('Tạm khóa', 'Vui lòng đợi $waitSeconds giây trước khi mở lại!');
        return;
      }

      if (isUnlockingDevice(deviceId)) return;

      unlockingByDevice[deviceId] = true;
      didStartUnlock = true;
      isUnlocking.value = true;
      final response = await _deviceService.unlockDevice(deviceId);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.snackbar('Mở khóa', 'Đang gửi lệnh mở cửa...');
        _startCooldown(deviceId);
      }
    } on DioException catch (e) {
      String msg = e.response?.data['message'] ?? 'Lỗi không xác định';
      Get.snackbar('Thất bại', msg, backgroundColor: Get.theme.colorScheme.error);
    } finally {
      if (didStartUnlock) {
        unlockingByDevice[deviceId] = false;
        isUnlocking.value = false;
      }
    }
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    super.onClose();
  }
}
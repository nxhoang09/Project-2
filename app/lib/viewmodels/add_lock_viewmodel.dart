import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:smart_lock_app/services/device_event_service.dart';
import '../services/ble_provisioning_service.dart';
import '../services/device_service.dart';
import '../services/auth_service.dart';

class AddLockViewModel extends GetxController {
  final deviceNameController = TextEditingController();
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var ownerId = ''.obs;
  var isSending = false.obs;
  var connectionStatus = 'Đang chờ kết nối Bluetooth...'.obs;
  var isWaitingForOnline = false.obs;
  Timer? _timeoutTimer;

  @override
  void onInit() {
    super.onInit();
    _loadUserId();
    Get.find<DeviceEventService>().initSocket(
      onStatusChanged: _handleStatusChanged,
    );
  }

  void _loadUserId() {
    final authService = Get.find<AuthService>();
    ownerId.value = authService.userId;
  }

  void _handleStatusChanged(dynamic data) {
    if (data is! Map) return;

    if (isWaitingForOnline.value && data['status'] == 'ONLINE') {
      _timeoutTimer?.cancel();
      _finishSetupSuccess();
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> sendConfigToLock() async {
    final ssid = ssidController.text.trim();
    final pass = passwordController.text;

    if (ssid.isEmpty) {
      Get.snackbar(
        'Thiếu thông tin',
        'Vui lòng nhập tên WiFi nhà bạn',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isSending.value = true;
    connectionStatus.value = 'Đang quét Bluetooth...';

    try {
      final bleService = Get.find<BleProvisioningService>();
      final macAddress = await bleService.provisionLock(
        ssid: ssid,
        password: pass,
        ownerId: ownerId.value,
        onProgress: (status) => connectionStatus.value = status,
      );

      connectionStatus.value = 'Đang đăng ký quyền làm chủ lên Server...';

      final deviceService = Get.find<DeviceService>();
      final deviceName = deviceNameController.text.trim();
      final claimResponse = await deviceService.claimDevice(
        macAddress,
        name: deviceName.isEmpty ? null : deviceName,
      );

      final deviceId = claimResponse.data['device_id'];
      if (deviceId is String && deviceId.isNotEmpty) {
        Get.find<DeviceEventService>().joinDeviceRoom(deviceId);
      }

      connectionStatus.value = 'Hoàn tất! Khóa đang khởi động lại...';
      isWaitingForOnline.value = true;
      _showWaitingDialog();
    } on BleProvisioningException catch (e) {
      connectionStatus.value = 'Kết nối Bluetooth thất bại.';
      Get.snackbar(
        'Lỗi',
        e.message,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? 'Lỗi từ Server NestJS';
      connectionStatus.value = 'Đăng ký thiết bị thất bại.';
      Get.snackbar(
        'Lỗi',
        errorMsg,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      connectionStatus.value = 'Lỗi hệ thống.';
      Get.snackbar(
        'Lỗi',
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isSending.value = false;
    }
  }

  // Hiển thị vòng xoay chờ khóa báo cáo lên Server
  void _showWaitingDialog() {
    Get.defaultDialog(
      title: "Đang hoàn tất",
      barrierDismissible: false, // Không cho bấm ra ngoài để đóng
      content: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Vui lòng kết nối lại điện thoại vào WiFi nhà bạn.",
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Đang chờ khóa lên mạng...",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );

    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (isWaitingForOnline.value) {
        _finishSetupSuccess(isTimeout: true);
      }
    });
  }

  void _finishSetupSuccess({bool isTimeout = false}) {
    isWaitingForOnline.value = false;
    if (Get.isDialogOpen == true) Get.back(); // Tắt Dialog

    Get.snackbar(
      'Thành công',
      isTimeout
          ? 'Đã gửi cấu hình! Khóa sẽ hiển thị khi kết nối mạng thành công.'
          : 'Khóa đã kết nối mạng và sẵn sàng sử dụng!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );

    Get.until((route) => route.isFirst);
  }

  @override
  void onClose() {
    _timeoutTimer?.cancel();
    Get.find<DeviceEventService>().removeStatusListener(_handleStatusChanged);
    deviceNameController.dispose();
    ssidController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

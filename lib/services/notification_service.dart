import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network_client.dart'; // Đảm bảo đường dẫn này đúng

class NotificationService extends GetxService {
  final Dio _dio = Get.find<NetworkClient>().dio;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  var isNotificationEnabled = false.obs;

  Future<NotificationService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isNotificationEnabled.value = prefs.getBool('notifications_enabled') ?? false;

    // 2. Lắng nghe thông báo khi app ĐANG MỞ (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'Thông báo',
          message.notification!.body ?? '',
          backgroundColor: Colors.white,
          colorText: Colors.black,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
          snackPosition: SnackPosition.TOP,
        );
      }
    });

    return this;
  }

  void toggleNotification() {
    bool turningOn = !isNotificationEnabled.value;
    
    Get.defaultDialog(
      title: turningOn ? "Bật thông báo" : "Tắt thông báo",
      middleText: turningOn 
          ? "Bạn có muốn nhận cảnh báo ngay lập tức khi có người lạ đột nhập không?" 
          : "Bạn sẽ không nhận được cảnh báo đột nhập nữa. Xác nhận tắt?",
      textConfirm: "Đồng ý",
      textCancel: "Hủy",
      confirmTextColor: Colors.white,
      buttonColor: turningOn ? const Color(0xFF00327D) : Colors.red,
      onConfirm: () async {
        Get.back(); // Đóng dialog
        if (turningOn) {
          await _enableNotifications();
        } else {
          await _disableNotifications();
        }
      },
    );
  }

  Future<void> _enableNotifications() async {
    try {
      // Xin quyền OS
      NotificationSettings settings = await _firebaseMessaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        Get.snackbar("Lỗi", "Bạn chưa cấp quyền thông báo trong Cài đặt hệ thống.");
        return;
      }

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _dio.post('/users/fcm-token', data: {'fcm_token': token});
        
        isNotificationEnabled.value = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', true);
        
        Get.snackbar("Thành công", "Đã bật cảnh báo an ninh!", 
            backgroundColor: Colors.green.withOpacity(0.1));
      }
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể bật thông báo. Vui lòng thử lại sau.");
    }
  }

  Future<void> _disableNotifications() async {
    try {
      await _dio.delete('/users/fcm-token');
      
      isNotificationEnabled.value = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', false);
      
      Get.snackbar("Đã tắt", "Bạn sẽ không nhận được thông báo nữa.");
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể tắt thông báo.");
    }
  }
}
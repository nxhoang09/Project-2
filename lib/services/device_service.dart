import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'network_client.dart';

class DeviceService {
  final Dio _dio = Get.find<NetworkClient>().dio;

  Future<Response> getMyDevices() async {
    return await _dio.get('/devices/my-devices');
  }

  Future<Response> unlockDevice(String deviceId) async {
    return await _dio.post('/devices/$deviceId/unlock');
  }

  Future<Response> claimDevice(String macAddress, {String? name}) async {
    return await _dio.post('/devices/claim', data: {
      'mac_address': macAddress,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });
  }

  Future<Response> getDeviceShares(String deviceId) async {
    return await _dio.get('/devices/$deviceId/shares');
  }

  Future<Response> shareDevice({
    required String deviceId,
    required String email,
    required String role,
  }) async {
    return await _dio.post('/devices/$deviceId/share', data: {
      'email': email,
      'role': role,
    });
  }

  Future<Response> revokeShare({
    required String deviceId,
    required String email,
  }) async {
    final encodedEmail = Uri.encodeComponent(email);
    return await _dio.delete('/devices/$deviceId/share/$encodedEmail');
  }

  Future<Response> deleteDevice(String deviceId) async {
    return await _dio.delete('/devices/$deviceId');
  }
}
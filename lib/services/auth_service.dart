import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'network_client.dart';

class AuthService extends GetxService {
  final Dio _dio = Get.find<NetworkClient>().dio;
  String userId = '';

  Future<Response> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      
      userId = response.data['user']['id']; 
    }
    return response;
  }
  Future<Response> register(String fullName, String email, String password) async {
    return await _dio.post('/auth/register', data: {
      'full_name': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<Response> forgotPassword(String email) async {
    return await _dio.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return await _dio.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<Response> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _dio.post('/auth/change-password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }
} 
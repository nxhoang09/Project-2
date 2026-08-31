import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../views/login_view.dart';
import '../viewmodels/login_viewmodel.dart';
import '../viewmodels/activity_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/face_profiles_viewmodel.dart';
import '../viewmodels/main_wrapper_viewmodel.dart';
import '../services/activity_service.dart';
import '../services/device_event_service.dart';
import '../services/auth_service.dart';

class NetworkClient {
  static String get baseUrl => dotenv.env['API_BASE_URL_LOCAL'] ?? 'http://127.0.0.1:3000'; 
  late Dio dio;
  bool _isLoggingOut = false;

  NetworkClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      
      onError: (DioException e, handler) async {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 && _shouldSkipAuthFlow(e.requestOptions)) {
          return handler.next(e);
        }

        // NẾU LỖI 401 (HẾT HẠN ACCESS TOKEN)
        if (statusCode == 401) {
          bool isRefreshed = await _refreshToken();

          if (isRefreshed) {
            final prefs = await SharedPreferences.getInstance();
            final newToken = prefs.getString('access_token');
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryDio = Dio(BaseOptions(baseUrl: baseUrl));
            try {
              final retryResponse = await retryDio.fetch(e.requestOptions);
              return handler.resolve(retryResponse); 
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          } else {
            await _logoutAndRedirect();
            return handler.next(e);
          }
        }
        return handler.next(e);
      },
    ));
  }

  bool _shouldSkipAuthFlow(RequestOptions options) {
    final path = options.path.toLowerCase();
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/forgot-password') ||
      path.contains('/auth/reset-password');
  }
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      final userId = prefs.getString('user_id');

      if (refreshToken == null || userId == null) return false;
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await refreshDio.post('/auth/refresh', data: {
        'userId': userId,
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setString('access_token', response.data['access_token']);
        await prefs.setString('refresh_token', response.data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _logoutAndRedirect() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _cleanupSession();
    if (Get.isRegistered<LoginViewModel>()) {
      Get.find<LoginViewModel>().clearFields();
    }
    
    Get.snackbar(
      'Phiên đăng nhập hết hạn', 
      'Vui lòng đăng nhập lại để tiếp tục.',
      backgroundColor: const Color(0xFFBA1A1A), 
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      maxWidth: 400, 
    );
    Get.offAll(() => const LoginView());
    _isLoggingOut = false;
  }

  void _cleanupSession() {
    if (Get.isRegistered<DeviceEventService>()) {
      Get.find<DeviceEventService>().disposeSocket();
    }
    if (Get.isRegistered<ActivityService>()) {
      Get.find<ActivityService>().disposeSocket();
    }
    if (Get.isRegistered<DashboardViewModel>()) {
      Get.delete<DashboardViewModel>(force: true);
    }
    if (Get.isRegistered<FaceProfilesViewModel>()) {
      Get.delete<FaceProfilesViewModel>(force: true);
    }
    if (Get.isRegistered<ActivityViewModel>()) {
      Get.delete<ActivityViewModel>(force: true);
    }
    if (Get.isRegistered<MainWrapperViewModel>()) {
      Get.delete<MainWrapperViewModel>(force: true);
    }
    if (Get.isRegistered<AuthService>()) {
      Get.find<AuthService>().userId = '';
    }
  }
}
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, MultipartFile, FormData;
import 'network_client.dart';

class UserService extends GetxService {
  final Dio _dio = Get.find<NetworkClient>().dio;

  Future<Response> getProfile() async {
    return await _dio.get('/users/me');
  }

  Future<Response> updateProfile({required String fullName}) async {
    return await _dio.patch('/users/me', data: {
      'full_name': fullName,
    });
  }

  Future<Response> uploadAvatar(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    return await _dio.post(
      '/users/me/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}

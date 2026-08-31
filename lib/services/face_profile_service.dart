import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'network_client.dart';

class FaceProfileService {
  final Dio _dio = Get.find<NetworkClient>().dio;

  Future<Response> getMyFaceProfiles() async {
    return await _dio.get('/face-profiles/my');
  }

  Future<Response> enrollFace({required String deviceId, required String name}) async {
    return await _dio.post('/face-profiles/enroll', data: {
      'deviceId': deviceId,
      'name': name,
    });
  }

  Future<Response> deleteFace(String profileId) async {
    return await _dio.delete('/face-profiles/$profileId');
  }

  Future<Response> assignFaceToDevice(String profileId, String deviceId) async {
    return await _dio.post('/face-profiles/$profileId/assign', data: {
      'deviceId': deviceId,
    });
  }
}

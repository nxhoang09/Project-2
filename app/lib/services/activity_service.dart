import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'network_client.dart';

class ActivityService extends GetxService {
  final Dio _dio = Get.find<NetworkClient>().dio;
  IO.Socket? _socket;
  String? _currentRoom;

  Future<Response> getLogs(String deviceId, int page, int limit) async {
    return await _dio.get('/$deviceId/logs?page=$page&limit=$limit');
  }
  void initSocket(Function(dynamic) onNewLogReceived) {
    if (_socket != null) return;

    _socket = IO.io(NetworkClient.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print('✅ Đã kết nối Socket Logs');
      if (_currentRoom != null) {
        _socket!.emit('join_device_room', _currentRoom);
      }
    });
    _socket!.on('new_access_log', (data) {
      onNewLogReceived(data);
    });
  }
  void joinDeviceRoom(String deviceId) {
    if (deviceId == 'all' || deviceId.isEmpty) return;
    if (_currentRoom != null && _currentRoom != deviceId && _socket != null) {
      _socket!.emit('leave_device_room', _currentRoom);
    }
    _currentRoom = deviceId;
    if (_socket != null) {
      _socket!.emit('join_device_room', deviceId);
    }
  }
  void disposeSocket() {
    if (_socket == null) return;
    if (_currentRoom != null) {
      _socket!.emit('leave_device_room', _currentRoom);
      _currentRoom = null;
    }
    _socket!.disconnect();
    _socket = null;
  }
}
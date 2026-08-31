import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'network_client.dart';

class DeviceEventService extends GetxService {
  IO.Socket? _socket;
  final Set<String> _pendingRooms = {};
  final Set<Function(dynamic)> _unlockListeners = {};
  final Set<Function(dynamic)> _statusListeners = {};
  bool _unlockListenerBound = false;
  bool _statusListenerBound = false;

  void initSocket({
    Function(dynamic)? onUnlockResult,
    Function(dynamic)? onStatusChanged,
  }) {
    if (_socket == null) {
      _socket = IO.io(NetworkClient.baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket!.onConnect((_) {
        for (final deviceId in _pendingRooms) {
          _socket!.emit('join_device_room', deviceId);
        }
        _pendingRooms.clear();
        print('✅ Da ket noi Socket Events');
      });
    }

    if (onUnlockResult != null) {
      _unlockListeners.add(onUnlockResult);
    }

    if (onStatusChanged != null) {
      _statusListeners.add(onStatusChanged);
    }

    if (!_unlockListenerBound) {
      _socket!.on('unlock_result', (data) {
        for (final listener in _unlockListeners) {
          listener(data);
        }
      });
      _unlockListenerBound = true;
    }

    if (!_statusListenerBound) {
      _socket!.on('device_status_changed', (data) {
        for (final listener in _statusListeners) {
          listener(data);
        }
      });
      _statusListenerBound = true;
    }
  }

  void joinDeviceRoom(String deviceId) {
    if (deviceId.isEmpty) return;
    if (_socket == null || !(_socket!.connected)) {
      _pendingRooms.add(deviceId);
      return;
    }
    _socket!.emit('join_device_room', deviceId);
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket = null;
    _pendingRooms.clear();
    _unlockListeners.clear();
    _statusListeners.clear();
    _unlockListenerBound = false;
    _statusListenerBound = false;
  }
  // THÊM HÀM NÀY VÀO CUỐI CLASS DeviceEventService
  void removeStatusListener(Function(dynamic) listener) {
    _statusListeners.remove(listener);
  }
}

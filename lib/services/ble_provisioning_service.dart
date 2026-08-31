import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

class BleProvisioningException implements Exception {
  final String message;
  BleProvisioningException(this.message);

  @override
  String toString() => message;
}

class BleProvisioningService {
  static const Duration _scanTimeout = Duration(seconds: 12);
  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _responseTimeout = Duration(seconds: 12);

  Future<String> provisionLock({
    required String ssid,
    required String password,
    required String ownerId,
    void Function(String status)? onProgress,
  }) async {
    await _ensurePermissions();
    await _ensureBluetoothReady();

    final namePrefix = _deviceNamePrefix();
    final serviceUuid = Guid(_requireEnv('BLE_SERVICE_UUID'));
    final rxUuid = Guid(_requireEnv('BLE_CHARACTERISTIC_UUID_RX'));
    final txUuid = Guid(_requireEnv('BLE_CHARACTERISTIC_UUID_TX'));

    onProgress?.call('Đang quét Bluetooth...');
    final device = await _scanForDevice(namePrefix);

    onProgress?.call('Đang kết nối với khóa qua BLE...');
    await device.connect(
      timeout: _connectTimeout,
      autoConnect: false,
      license: License.free,
    );
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (item) => item.uuid == serviceUuid,
        orElse: () => throw BleProvisioningException(
          'Không tìm thấy dịch vụ BLE của khóa.',
        ),
      );
      final rxChar = service.characteristics.firstWhere(
        (item) => item.uuid == rxUuid,
        orElse: () => throw BleProvisioningException(
          'Không tìm thấy kênh nhận dữ liệu BLE.',
        ),
      );
      final txChar = service.characteristics.firstWhere(
        (item) => item.uuid == txUuid,
        orElse: () => throw BleProvisioningException(
          'Không tìm thấy kênh phản hồi BLE.',
        ),
      );

      await txChar.setNotifyValue(true);

      final responseCompleter = Completer<String>();
      final buffer = StringBuffer();
      StreamSubscription<List<int>>? subscription;

      subscription = txChar.onValueReceived.listen((value) {
        if (responseCompleter.isCompleted) return;

        final chunk = utf8.decode(value, allowMalformed: true);
        buffer.write(chunk);
        final content = buffer.toString();
        if (!content.contains('}')) {
          return;
        }

        try {
          final decoded = jsonDecode(content);
          if (decoded is Map && decoded['mac_address'] != null) {
            final mac = decoded['mac_address'].toString();
            if (mac.isNotEmpty) {
              responseCompleter.complete(mac);
              subscription?.cancel();
            }
          }
        } catch (_) {
          return;
        }
      });

      onProgress?.call('Đang gửi cấu hình đến khóa...');
      final payload = jsonEncode({
        'ssid': ssid,
        'password': password,
        'owner_id': ownerId,
      });

      await rxChar.write(
        utf8.encode(payload),
        withoutResponse: false,
        allowLongWrite: true,
      );

      onProgress?.call('Đang nhận phản hồi từ khóa...');
      final macAddress = await responseCompleter.future.timeout(
        _responseTimeout,
        onTimeout: () {
          throw BleProvisioningException(
            'Không nhận được phản hồi từ khóa qua BLE.',
          );
        },
      );

      return macAddress;
    } finally {
      await device.disconnect();
    }
  }

  Future<void> _ensureBluetoothReady() async {
    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      throw BleProvisioningException('Thiết bị không hỗ trợ Bluetooth.');
    }

    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      throw BleProvisioningException('Vui lòng bật Bluetooth để tiếp tục.');
    }
  }

  Future<void> _ensurePermissions() async {
    final permissions = <Permission>[];
    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ]);
    } else if (Platform.isIOS) {
      permissions.add(Permission.bluetooth);
    }

    if (permissions.isEmpty) {
      return;
    }

    final statuses = await permissions.request();
    final denied = statuses.entries
        .where((entry) => !entry.value.isGranted)
        .toList();
    if (denied.isNotEmpty) {
      throw BleProvisioningException(
        'Vui lòng cấp quyền Bluetooth để cấu hình khóa.',
      );
    }
  }

  String _deviceNamePrefix() {
    final prefix = dotenv.env['BLE_DEVICE_NAME_PREFIX']?.trim();
    if (prefix != null && prefix.isNotEmpty) {
      return prefix;
    }
    return 'SmartLock_';
  }

  String _requireEnv(String key) {
    final value = dotenv.env[key]?.trim() ?? '';
    if (value.isEmpty) {
      throw BleProvisioningException('Thiếu cấu hình $key trong file .env.');
    }
    return value;
  }

  Future<BluetoothDevice> _scanForDevice(String prefix) async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }

    final completer = Completer<BluetoothDevice>();
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = _resolveDeviceName(result);
        if (name.startsWith(prefix)) {
          if (!completer.isCompleted) {
            completer.complete(result.device);
          }
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: _scanTimeout,
      withKeywords: [prefix],
      androidScanMode: AndroidScanMode.lowLatency,
    );

    try {
      return await completer.future.timeout(
        _scanTimeout,
        onTimeout: () {
          throw BleProvisioningException('Không tìm thấy khóa Bluetooth ở gần.');
        },
      );
    } finally {
      await FlutterBluePlus.stopScan();
      await subscription.cancel();
    }
  }

  String _resolveDeviceName(ScanResult result) {
    final advName = result.advertisementData.advName;
    if (advName.isNotEmpty) {
      return advName;
    }

    final localName = result.advertisementData.localName;
    if (localName.isNotEmpty) {
      return localName;
    }

    final deviceName = result.device.name;
    if (deviceName.isNotEmpty) {
      return deviceName;
    }

    return result.device.platformName;
  }
}

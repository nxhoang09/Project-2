import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/activity_service.dart';
import '../services/device_service.dart';

class ActivityViewModel extends GetxController {
  final ActivityService _activityService = Get.find<ActivityService>();
  final DeviceService _deviceService = Get.find<DeviceService>();

  var devices = [].obs;
  var selectedDeviceId = 'all'.obs; 
  
  var allLogs = [].obs; 
  var filteredLogs = [].obs; 
  var currentFilter = 'all'.obs; 
  var isLoading = true.obs;

  final Map<String, List<dynamic>> _cachedLogsByDevice = {};
  final Map<String, String> _deletedDeviceNames = {};

  int currentPage = 1;
  var hasMore = true.obs; 
  var isLoadMore = false.obs; 
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    _connectSocket();
    _initData();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
        if (selectedDeviceId.value != 'all' && !isDeletedDevice(selectedDeviceId.value)) {
          fetchLogs(selectedDeviceId.value);
        }
      }
    });
  }

  Future<void> _initData() async {
    isLoading.value = true;
    final devRes = await _deviceService.getMyDevices();
    if (devRes.statusCode == 200) devices.assignAll(devRes.data);

    if (devices.isNotEmpty) {
      final firstId = devices.first['id']?.toString() ?? '';
      if (selectedDeviceId.value == 'all' || selectedDeviceId.value.isEmpty) {
        selectedDeviceId.value = firstId;
      }
      changeDevice(selectedDeviceId.value);
    }
    isLoading.value = false;
  }

  Future<void> fetchLogs(String deviceId, {bool isRefresh = false}) async {
    if (isDeletedDevice(deviceId)) return;
    if (isRefresh) {
      currentPage = 1;
      hasMore.value = true;
      allLogs.clear();
      if(devices.isNotEmpty) isLoading.value = true; 
    } else {
      if (!hasMore.value || isLoadMore.value) return;
      isLoadMore.value = true; 
    }

    try {
      final response = await _activityService.getLogs(deviceId, currentPage, 20);
      
      if (response.statusCode == 200) {
        List newLogs = response.data;
        if (newLogs.length < 20) hasMore.value = false;

        if (isRefresh) {
          allLogs.assignAll(newLogs);
        } else {
          allLogs.addAll(newLogs); 
        }
        _cacheLogs(deviceId, newLogs, isRefresh: isRefresh);
        applyFilter(currentFilter.value); 
        currentPage++; 
      }
    } catch (e) {
      print('Lỗi: $e');
    } finally {
      isLoading.value = false;
      isLoadMore.value = false;
    }
  }
  void _connectSocket() {
    _activityService.initSocket((newData) {
      if (newData is Map) {
        final deviceId = newData['device_id']?.toString() ?? '';
        if (selectedDeviceId.value != 'all' && deviceId.isNotEmpty && deviceId != selectedDeviceId.value) {
          return;
        }
        if (deviceId.isNotEmpty) {
          final cached = _cachedLogsByDevice[deviceId] ?? <dynamic>[];
          cached.insert(0, newData);
          _cachedLogsByDevice[deviceId] = cached;
        }
      }
      allLogs.insert(0, newData);
      applyFilter(currentFilter.value);
    });
  }

  void changeDevice(String newDeviceId) {
    selectedDeviceId.value = newDeviceId;
    if (isDeletedDevice(newDeviceId)) {
      allLogs.assignAll(_cachedLogsByDevice[newDeviceId] ?? []);
      applyFilter(currentFilter.value);
      return;
    }

    _activityService.joinDeviceRoom(newDeviceId); 
    fetchLogs(newDeviceId, isRefresh: true);
  }

  void applyFilter(String filter) {
    currentFilter.value = filter;
    if (filter == 'all') {
      filteredLogs.assignAll(allLogs);
    } else if (filter == 'member') {
      filteredLogs.assignAll(allLogs.where((log) => log['event_type'] != 'INTRUDER_ALARM'));
    } else if (filter == 'alert') {
      filteredLogs.assignAll(allLogs.where((log) => log['event_type'] == 'INTRUDER_ALARM'));
    }
  }

  void handleDeviceDeleted(String deviceId, {String deviceName = ''}) {
    if (deviceId.isEmpty) return;

    if (deviceName.isNotEmpty) {
      _deletedDeviceNames[deviceId] = deviceName;
    }

    final index = devices.indexWhere((device) => device['id'] == deviceId);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(devices[index]);
      updated['is_deleted'] = true;
      devices[index] = updated;
    } else {
      devices.add({
        'id': deviceId,
        'name': deviceName,
        'is_deleted': true,
      });
    }
    devices.refresh();

    if (selectedDeviceId.value == deviceId) {
      allLogs.assignAll(_cachedLogsByDevice[deviceId] ?? []);
      applyFilter(currentFilter.value);
    }
  }

  bool isDeletedDevice(String deviceId) {
    if (deviceId.isEmpty || deviceId == 'all') return false;
    if (_deletedDeviceNames.containsKey(deviceId)) return true;
    return devices.any((device) => device['id'] == deviceId && device['is_deleted'] == true);
  }

  List<dynamic> get dropdownDevices {
    final List<dynamic> items = List<dynamic>.from(devices);
    final selectedId = selectedDeviceId.value;
    if (selectedId.isEmpty || selectedId == 'all') return items;

    final exists = items.any((device) => device['id']?.toString() == selectedId);
    if (!exists) {
      final name = _deletedDeviceNames[selectedId] ?? 'Khóa đã xóa';
      items.insert(0, {'id': selectedId, 'name': name, 'is_deleted': true});
    }
    return items;
  }

  String? get dropdownValue {
    final items = dropdownDevices;
    if (items.isEmpty) return null;

    final selectedId = selectedDeviceId.value;
    final exists = items.any((device) => device['id']?.toString() == selectedId);
    if (selectedId.isNotEmpty && selectedId != 'all' && exists) {
      return selectedId;
    }
    return items.first['id']?.toString();
  }

  void _cacheLogs(String deviceId, List<dynamic> newLogs, {required bool isRefresh}) {
    if (deviceId.isEmpty || deviceId == 'all') return;
    final existing = _cachedLogsByDevice[deviceId] ?? <dynamic>[];
    if (isRefresh) existing.clear();
    existing.addAll(newLogs);
    _cachedLogsByDevice[deviceId] = existing;
  }

  @override
  void onClose() {
    scrollController.dispose();
    _activityService.disposeSocket();
    super.onClose();
  }
}
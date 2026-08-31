import 'package:get/get.dart';
import 'package:smart_lock_app/services/notification_service.dart';

class MainWrapperViewModel extends GetxController {
  final NotificationService _notificationService = Get.find<NotificationService>();
  var selectedIndex = 0.obs;
  var openAddFaceRequested = false.obs;

  void changePage(int index) {
    selectedIndex.value = index;
  }

  void requestAddFaceOnMembers() {
    openAddFaceRequested.value = true;
    changePage(1);
  }

  void toggleNotification() {
    _notificationService.toggleNotification();
  }
  RxBool get isNotificationEnabled => _notificationService.isNotificationEnabled;
}
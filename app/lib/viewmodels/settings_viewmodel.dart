import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/device_event_service.dart';
import '../views/login_view.dart';
import 'activity_viewmodel.dart';
import 'dashboard_viewmodel.dart';
import 'face_profiles_viewmodel.dart';
import 'login_viewmodel.dart';
import 'main_wrapper_viewmodel.dart';
import 'user_profile_viewmodel.dart';

class SettingsViewModel extends GetxController {
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _cleanupSession();
    if (Get.isRegistered<LoginViewModel>()) {
      Get.find<LoginViewModel>().clearFields();
    }
    Get.offAll(() => const LoginView());
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
    if (Get.isRegistered<UserProfileViewModel>()) {
      Get.delete<UserProfileViewModel>(force: true);
    }
    if (Get.isRegistered<MainWrapperViewModel>()) {
      Get.delete<MainWrapperViewModel>(force: true);
    }
    if (Get.isRegistered<AuthService>()) {
      Get.find<AuthService>().userId = '';
    }
  }
}

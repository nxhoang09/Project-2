import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_lock_app/services/activity_service.dart';
import 'package:smart_lock_app/services/ble_provisioning_service.dart';
import 'package:smart_lock_app/services/device_service.dart';
import 'package:smart_lock_app/services/device_event_service.dart';
import 'package:smart_lock_app/services/face_profile_service.dart';
import 'package:smart_lock_app/services/user_service.dart';
import 'package:smart_lock_app/views/main_wrapper_view.dart';
import 'utils/app_theme.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart'; 
import 'services/network_client.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🌙 Xử lý tin nhắn chạy ngầm: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);



  await dotenv.load(fileName: ".env");

  Get.put(NetworkClient()); 
  Get.put(AuthService());
  Get.put(UserService());
  Get.put(DeviceService());
  Get.put(ActivityService());
  Get.put(BleProvisioningService());
  Get.put(DeviceEventService());
  Get.put(FaceProfileService());
  final notificationService = Get.put(NotificationService());
  await notificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');
  final storedDarkMode = prefs.getBool('is_dark_mode');
  final ThemeMode themeMode = storedDarkMode == null
      ? ThemeMode.system
      : (storedDarkMode ? ThemeMode.dark : ThemeMode.light);
  
  Widget initialRoute = (accessToken != null && accessToken.isNotEmpty) 
      ? const MainWrapperView()
      : const LoginView();

  runApp(SmartLockApp(initialRoute: initialRoute, themeMode: themeMode));
}

class SmartLockApp extends StatelessWidget {
  final Widget initialRoute;
  final ThemeMode themeMode;
  const SmartLockApp({super.key, required this.initialRoute, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SecureHome',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: initialRoute, 
    );
  }
}
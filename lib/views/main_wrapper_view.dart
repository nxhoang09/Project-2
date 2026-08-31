import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_lock_app/views/activity_view.dart';
import 'package:smart_lock_app/views/face_profiles_view.dart';
import 'package:smart_lock_app/views/profile_view.dart';
import 'package:smart_lock_app/views/settings_view.dart';
import '../viewmodels/main_wrapper_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import 'dashboard_view.dart';

class MainWrapperView extends StatelessWidget {
  const MainWrapperView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(MainWrapperViewModel());
    final profileViewModel = Get.isRegistered<UserProfileViewModel>()
        ? Get.find<UserProfileViewModel>()
        : Get.put(UserProfileViewModel());
    final List<Widget> pages = [
      const DashboardView(),
      const FaceProfilesView(),
      const ActivityView(),
      const SettingsView(),
    ];

    return Scaffold(
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Obx(() {
            final name = profileViewModel.fullName.value.trim();
            final avatarUrl = profileViewModel.avatarUrl.value.trim();
            final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

            return InkWell(
              onTap: () => Get.to(() => const ProfileView()),
              borderRadius: BorderRadius.circular(24),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        initials,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),
        title: Text(
          'SecureHome',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        actions: [
          Obx((){
            return IconButton(
              onPressed: (){
                viewModel.toggleNotification();
              },
              icon: Icon(
                viewModel.isNotificationEnabled.value 
                    ? Icons.notifications
                    : Icons.notifications_off_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() => IndexedStack(
        index: viewModel.selectedIndex.value,
        children: pages,
      )),
      bottomNavigationBar: Obx(() => NavigationBar(
        selectedIndex: viewModel.selectedIndex.value,
        onDestinationSelected: viewModel.changePage,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF00327D)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.face_outlined), label: 'Members'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      )),
    );
  }
}
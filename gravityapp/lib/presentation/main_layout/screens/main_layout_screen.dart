import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../commuinity/screens/community_page.dart';
import '../../dashboard/screens/dashboard_view.dart';
import '../../dashboard/screens/sections/sync_status_section.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../messages/screens/messages_page.dart';
import '../../profile/screens/profile_page.dart';
import '../../coach_dashboard/screens/coach_dashboard_screen.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/main_bottom_nav.dart';
import '../../widgets/main_drawer.dart';
import '../controllers/main_layout_controller.dart';

class MainLayoutScreen extends GetView<MainLayoutController> {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFF6F7FA),

        // App Bar - Hide for Coach Dashboard (index 4) as it has its own header
        appBar: controller.currentIndex.value == 4
            ? null
            : MainAppBar(
                userName: controller.userName.value,
                onNotificationTap: controller.navigateToNotifications,
                onMenuTap: () {
                  Scaffold.of(context).openDrawer();
                },
                onSettingsTap: controller.navigateToSettings,
              ),

        // Drawer
        drawer: MainDrawer(
          userName: controller.userName.value,
          userType: controller.userType.value,
          onLogout: controller.handleLogout,
        ),

        // Body - Dynamic content based on selected tab
        body: controller.currentIndex.value == 4
            ? _buildBody() // CoachDashboardScreen handles its own SafeArea
            : SafeArea(
                child: Stack(
                  children: [
                    _buildBody(),
                    // Sticky sync status section that overlaps with header (only for dashboard)
                    if (controller.currentIndex.value == 0)
                      _buildStickySyncStatus(),
                  ],
                ),
              ),

        // Bottom Navigation Bar
        bottomNavigationBar: MainBottomNav(
          currentIndex: controller.currentIndex.value,
          onTap: controller.navigateToTab,
          userType: controller.userType.value,
        ),
      ),
    );
  }

  /// Build body content based on current index
  Widget _buildBody() {
    switch (controller.currentIndex.value) {
      case 0:
        return const DashboardView();
      case 1:
        return const CommunityPage();
      case 2:
        return const ProfilePage();
      case 3:
        return const MessagesPage();
      case 4:
        // Dashboard (coach only)
        return const CoachDashboardScreen();
      default:
        return const DashboardView();
    }
  }

  /// Build sticky sync status section that overlaps with header
  Widget _buildStickySyncStatus() {
    final dashboardController = Get.find<DashboardController>();
    return Positioned(
      //top: -25.h, // Position to overlap with header bottom (header is 180.h)
      left: 0,
      right: 0,
      child: SyncStatusSection(controller: dashboardController),
    );
  }
}

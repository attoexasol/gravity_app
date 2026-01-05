import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gravityapp/data/model/navigation_item.dart';
import '../../../core/services/preferences_service.dart';
import '../../aicoach/controllers/ai_coach_controller.dart';
import '../../community/controllers/community_controller.dart';
import '../../messages/controllers/messages_controllers.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../coach_dashboard/controllers/coach_dashboard_controller.dart';

class MainLayoutController extends GetxController {
  // Current selected navigation index
  final RxInt currentIndex = 0.obs;

  // Drawer state
  final RxBool isDrawerOpen = false.obs;

  // User type (from login)
  final Rx<String> userType = 'customer'.obs;

  // User name
  final RxString userName = 'User'.obs;

  /// Navigation items for bottom nav
  final List<NavigationItem> navigationItems = [
    NavigationItem(
      index: 0,
      label: 'Home',
      icon: 'home_outlined',
      route: '/home/dashboard',
    ),
    NavigationItem(
      index: 1,
      label: 'Community',
      icon: 'people_outline',
      route: '/home/community',
    ),
    NavigationItem(
      index: 2,
      label: 'Profile',
      icon: 'person_outline',
      route: '/home/profile',
    ),
    NavigationItem(
      index: 3,
      label: 'Settings',
      icon: 'settings_outlined',
      route: '/home/settings',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    // Ensure home tab (index 0) is selected on initialization
    currentIndex.value = 0;
    // Initialize user data from storage/auth service
    _loadUserData();
  }

  /// Load user data from preferences or auth service
  void _loadUserData() {
    // Load user name from storage
    final storedName = PreferencesService.getUserName();
    if (storedName != null && storedName.isNotEmpty) {
      userName.value = storedName;
    } else {
      userName.value = 'User';
    }

    // Load user type from PreferencesService
    final storedUserType = PreferencesService.getUserType();
    if (storedUserType != null && storedUserType.isNotEmpty) {
      userType.value = storedUserType;
    } else {
      userType.value = 'customer'; // Default to customer
    }
  }

  /// Navigate to a specific tab
  void navigateToTab(int index) {
    // For coaches, allow index 4 (Dashboard)
    // For customers, max index is 3 (Messages)
    final maxIndex = userType.value == 'coach' ? 4 : 3;
    
    if (index >= 0 && index <= maxIndex) {
      // Check if Home tab (index 0) is tapped again
      if (index == 0 && currentIndex.value == 0) {
        // User tapped Home tab while already on Dashboard page
        // Scroll to top of Dashboard page
        if (Get.isRegistered<DashboardController>()) {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.scrollToTop();
        }
        return; // Don't change the index since we're already on Dashboard
      }

      // Check if Community tab (index 1) is tapped again
      if (index == 1 && currentIndex.value == 1) {
        // User tapped Community tab while already on Community page
        // Scroll to top of Community page
        if (Get.isRegistered<CommunityController>()) {
          final communityController = Get.find<CommunityController>();
          communityController.scrollToTop();
        }
        return; // Don't change the index since we're already on Community
      }

      // Check if Messages tab (index 3) is tapped again
      if (index == 3 && currentIndex.value == 3) {
        // User tapped Messages tab while already on Messages page
        // Scroll to top of Messages page (conversations list)
        if (Get.isRegistered<MessagesController>()) {
          final messagesController = Get.find<MessagesController>();
          messagesController.scrollToTop();
        }
        return; // Don't change the index since we're already on Messages
      }

      // Check if Coach Dashboard tab (index 4) is tapped again
      if (index == 4 && currentIndex.value == 4) {
        // User tapped Dashboard tab while already on Coach Dashboard page
        // Scroll to top of Coach Dashboard page
        if (Get.isRegistered<CoachDashboardController>()) {
          final coachDashboardController = Get.find<CoachDashboardController>();
          coachDashboardController.scrollToTop();
        }
        return; // Don't change the index since we're already on Coach Dashboard
      }

      currentIndex.value = index;

      // Handle navigation based on index
      switch (index) {
        case 0:
          // Home - handled by MainLayoutScreen body
          break;
        case 1:
          // Community - handled by MainLayoutScreen body
          break;
        case 2:
          // AI Coach - Navigate to standalone screen
          Get.toNamed('/ai-coach');
          break;
        case 3:
          // Messages - handled by MainLayoutScreen body
          break;
        case 4:
          // Dashboard (coach only) - handled by MainLayoutScreen body
          break;
        default:
          break;
      }
    }
  }

  /// Toggle drawer
  void toggleDrawer() {
    isDrawerOpen.value = !isDrawerOpen.value;
  }

  /// Open drawer
  void openDrawer() {
    isDrawerOpen.value = true;
  }

  /// Close drawer
  void closeDrawer() {
    isDrawerOpen.value = false;
  }

  /// Handle notification tap
  void navigateToNotifications() {
    Get.toNamed('/notifications');
  }

  /// Handle settings tap
  void navigateToSettings() {
    Get.toNamed('/settings');
  }

  /// Handle logout
  Future<void> handleLogout() async {
    final confirmed = await Get.dialog<bool>(
      _buildLogoutDialog(),
      barrierDismissible: true,
    );

    if (confirmed == true) {
      // Clear user data and auth tokens
      await PreferencesService.clearAuthToken();
      await PreferencesService.clearUserData(); // Clear email and name

      // Delete AI Coach controller to prevent state reuse after logout
      if (Get.isRegistered<AiCoachController>()) {
        Get.delete<AiCoachController>(force: true);
      }

      // TODO: Call logout API if needed
      // await AuthService.logout();

      // Navigate to login screen and clear navigation stack
      Get.offAllNamed('/login');
    }
  }

  /// Build logout confirmation dialog
  Widget _buildLogoutDialog() {
    return AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD4183D)),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  /// Get current navigation item
  NavigationItem get currentNavigationItem {
    return navigationItems[currentIndex.value];
  }
}

import 'package:get/get.dart';
import 'package:gravityapp/data/model/client_user.dart';

class CoachDashboardController extends GetxController {
  // Sample user data - in production, this would come from an API
  final RxList<ClientUser> users = <ClientUser>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
  }

  void _loadUsers() {
    // Sample data matching the React code
    users.value = [
      ClientUser(
        id: 1,
        name: 'John R.',
        avatar: 'https://i.pravatar.cc/150?img=11',
        compliance: 92,
        status: 'high',
        todayScore: 95,
        alerts: [],
      ),
      ClientUser(
        id: 2,
        name: 'Emma L.',
        avatar: 'https://i.pravatar.cc/150?img=5',
        compliance: 68,
        status: 'medium',
        todayScore: 72,
        alerts: ['Low hydration'],
      ),
      ClientUser(
        id: 3,
        name: 'Alex K.',
        avatar: 'https://i.pravatar.cc/150?img=8',
        compliance: 41,
        status: 'low',
        todayScore: 38,
        alerts: ['Missed sleep goal', 'Low activity'],
      ),
      ClientUser(
        id: 4,
        name: 'Sarah M.',
        avatar: 'https://i.pravatar.cc/150?img=1',
        compliance: 88,
        status: 'high',
        todayScore: 90,
        alerts: [],
      ),
      ClientUser(
        id: 5,
        name: 'Mike T.',
        avatar: 'https://i.pravatar.cc/150?img=12',
        compliance: 75,
        status: 'medium',
        todayScore: 78,
        alerts: ['Below step goal'],
      ),
      ClientUser(
        id: 6,
        name: 'Lisa W.',
        avatar: 'https://i.pravatar.cc/150?img=9',
        compliance: 96,
        status: 'high',
        todayScore: 98,
        alerts: [],
      ),
      ClientUser(
        id: 7,
        name: 'Tom H.',
        avatar: 'https://i.pravatar.cc/150?img=13',
        compliance: 52,
        status: 'low',
        todayScore: 48,
        alerts: ['Poor sleep quality'],
      ),
      ClientUser(
        id: 8,
        name: 'Nina P.',
        avatar: 'https://i.pravatar.cc/150?img=10',
        compliance: 84,
        status: 'high',
        todayScore: 86,
        alerts: [],
      ),
    ];
  }

  // Computed properties for summary cards
  int get highComplianceCount {
    return users.where((u) => u.status == 'high').length;
  }

  int get mediumComplianceCount {
    return users.where((u) => u.status == 'medium').length;
  }

  int get lowComplianceCount {
    return users.where((u) => u.status == 'low').length;
  }

  // Navigate to notifications
  void navigateToNotifications() {
    // TODO: Implement navigation to notifications
    Get.snackbar('Notifications', 'Notifications feature coming soon');
  }

  // Navigate to settings
  void navigateToSettings() {
    Get.toNamed('/settings');
  }
}


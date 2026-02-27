import 'package:get/get.dart';

enum NotificationType {
  message,
  payment,
  streak,
  offer,
  social,
  reminder,
  update,
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeText,
    required this.type,
    required this.isUnread,
    required this.isHighPriority,
    this.actionText,
  });

  final String id;
  final String title;
  final String description;
  final String timeText;
  final NotificationType type;
  bool isUnread;
  final bool isHighPriority;
  final String? actionText;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? description,
    String? timeText,
    NotificationType? type,
    bool? isUnread,
    bool? isHighPriority,
    String? actionText,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeText: timeText ?? this.timeText,
      type: type ?? this.type,
      isUnread: isUnread ?? this.isUnread,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      actionText: actionText ?? this.actionText,
    );
  }
}

class NotificationsController extends GetxController {
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    ever(notifications, (_) => _updateUnreadCount());
    loadMockNotifications();
  }

  void _updateUnreadCount() {
    unreadCount.value =
        notifications.where((n) => n.isUnread).length;
  }

  void loadMockNotifications() {
    notifications.assignAll([
      NotificationItem(
        id: '1',
        title: 'New Message from Coach Emily',
        description:
            'Great job on your water intake today! Keep up the excellent work.',
        timeText: '15m ago',
        type: NotificationType.message,
        isUnread: true,
        isHighPriority: true,
        actionText: 'Reply →',
      ),
      NotificationItem(
        id: '2',
        title: 'Payment Method Expiring',
        description:
            'Your credit card ending in .... 4242 will expire soon. Please update your payment method.',
        timeText: '30m ago',
        type: NotificationType.payment,
        isUnread: true,
        isHighPriority: true,
        actionText: 'Update Payment Method →',
      ),
      NotificationItem(
        id: '3',
        title: 'Streak Achievement! 🎉',
        description:
            "Congratulations! You've logged meals for 7 days straight. Keep up the great work!",
        timeText: '2h ago',
        type: NotificationType.streak,
        isUnread: true,
        isHighPriority: false,
        actionText: null,
      ),
      NotificationItem(
        id: '4',
        title: 'Special Offer: Premium Upgrade',
        description:
            'Get 20% off Premium membership this month! Unlock personalized meal plans and advanced analytics.',
        timeText: '3h ago',
        type: NotificationType.offer,
        isUnread: false,
        isHighPriority: false,
        actionText: null,
      ),
      NotificationItem(
        id: '5',
        title: 'New Post from Sarah',
        description: 'Sarah shared a healthy recipe in the community',
        timeText: '4h ago',
        type: NotificationType.social,
        isUnread: false,
        isHighPriority: false,
        actionText: null,
      ),
      NotificationItem(
        id: '6',
        title: 'Hydration Reminder',
        description:
            "You're below your daily water goal. Try to drink more water before bedtime!",
        timeText: '5h ago',
        type: NotificationType.reminder,
        isUnread: false,
        isHighPriority: false,
        actionText: null,
      ),
      NotificationItem(
        id: '7',
        title: '5 Likes on Your Post',
        description: 'Your healthy lunch photo got 5 likes!',
        timeText: '8h ago',
        type: NotificationType.social,
        isUnread: false,
        isHighPriority: false,
        actionText: null,
      ),
      NotificationItem(
        id: '8',
        title: 'App Update Available',
        description:
            'A new version of Gravity is available with improved AI meal analysis and bug fixes.',
        timeText: 'Yesterday',
        type: NotificationType.update,
        isUnread: false,
        isHighPriority: false,
        actionText: null,
      ),
    ]);
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index >= 0 && notifications[index].isUnread) {
      final updated = notifications.toList();
      updated[index] = updated[index].copyWith(isUnread: false);
      notifications.assignAll(updated);
    }
  }

  void markAllAsRead() {
    notifications.assignAll(
      notifications.map((n) => n.copyWith(isUnread: false)).toList(),
    );
  }

  void onBack() {
    Get.back();
  }
}

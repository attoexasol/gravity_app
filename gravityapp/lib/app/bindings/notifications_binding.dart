import 'package:get/get.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../presentation/notifications/controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsRepository>(() => NotificationsRepository());
    Get.lazyPut<NotificationsController>(() => NotificationsController());
  }
}

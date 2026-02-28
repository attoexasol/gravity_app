import 'package:get/get.dart';
import '../../data/remote/notifications_api.dart';
import '../../presentation/notifications/controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsApi>(() => NotificationsApi());
    Get.lazyPut<NotificationsController>(() => NotificationsController());
  }
}

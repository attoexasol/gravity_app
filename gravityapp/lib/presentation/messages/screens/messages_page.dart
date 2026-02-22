import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/messages_controller.dart';
import '../views/messages_view.dart';

/// Messages tab: professional inbox (users from API + Firestore conversation preview).
/// Uses [InboxController] and [MessagesView]. Tap user -> [ChatScreen].
class MessagesPage extends GetView<InboxController> {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<InboxController>()) {
      Get.put(InboxController());
    }
    return const MessagesView();
  }
}

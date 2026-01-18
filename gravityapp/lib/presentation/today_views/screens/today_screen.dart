import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/today_controller.dart';
import 'sections/today_header.dart';
import 'sections/pillar_status_section.dart';
import 'sections/weight_journey_section.dart';
import 'sections/wins_today_section.dart';
import 'sections/one_thing_to_watch_section.dart';
import 'sections/reflection_section.dart';
import 'sections/done_button_section.dart';
import 'modals/log_weigh_in_modal.dart';

class TodayScreen extends GetView<TodayController> {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                TodayHeader(controller: controller),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 24.h),
                        // Pillar Status
                        PillarStatusSection(controller: controller),
                        SizedBox(height: 16.h),
                        // Weight Journey
                        WeightJourneySection(controller: controller),
                        SizedBox(height: 16.h),
                        // Wins Today
                        WinsTodaySection(),
                        SizedBox(height: 16.h),
                        // One Thing to Watch
                        OneThingToWatchSection(),
                        SizedBox(height: 16.h),
                        // Reflection
                        ReflectionSection(controller: controller),
                        SizedBox(height: 16.h),
                        // Done Button
                        DoneButtonSection(controller: controller),
                        SizedBox(height: 96.h), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Modal overlay
            Obx(() => controller.showWeighInModal.value
                ? LogWeighInModal(controller: controller)
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}


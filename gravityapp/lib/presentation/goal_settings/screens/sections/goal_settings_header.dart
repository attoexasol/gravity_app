import 'dart:ui';
import 'package:flutter/material.dart';
// if using SVG icons
import 'package:flutter_animate/flutter_animate.dart'; // for motion-like animation

Widget buildHeader() {
  return Column(
    children: [
      // Background Gradient Header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 56, // pt-14
          bottom: 32, // pb-8
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A2342),
              Color(0xFF00B8A9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            // Animated content (similar to framer motion)
            Animate(
              effects: [
                FadeEffect(duration: 400.ms),
                MoveEffect(begin: const Offset(0, -20), end: Offset.zero, duration: 400.ms),
              ],
              child: Column(
                children: [
                  // Round blurred icon container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.track_changes, // Replace Target icon
                            size: 40,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Set Your Goals",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Let's personalize your wellness journey",
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

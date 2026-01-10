import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';

class LoadingSpinner extends StatefulWidget {
  const LoadingSpinner({super.key});

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.w,
      height: 64.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating gradient circle
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 64.w,
              height: 64.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00B8A9),
                    const Color(0xFF0A2342),
                  ],
                ),
              ),
            ),
          ),
          // Inner white circle with icon
          Container(
            width: 48.w,
            height: 48.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: const Color(0xFF00B8A9),
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }
}


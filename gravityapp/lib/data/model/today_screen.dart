import 'package:flutter/material.dart';

enum PillarStatus {
  onTrack,
  borderline,
  missed,
  notScheduled,
  logged,
}

class Pillar {
  final String name;
  final PillarStatus status;
  final String detail;
  final IconData icon;

  Pillar({
    required this.name,
    required this.status,
    required this.detail,
    required this.icon,
  });
}


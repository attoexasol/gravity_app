import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double value;
  final double max;
  final String label;
  final IconData? icon;
  final Color color;
  final String? suffix;
  final String? trend;
  final double? trendValue;

  const ProgressRing({
    super.key,
    required this.value,
    required this.max,
    required this.label,
    this.icon,
    required this.color,
    this.suffix,
    this.trend,
    this.trendValue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 59,
          height: 59,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) Icon(icon, size: 16, color: color),
                  Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.black54)),
        if (trend != null && trendValue != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                trend == 'down' ? Icons.arrow_downward : trend == 'up' ? Icons.arrow_upward : Icons.remove,
                size: 14,
                color: trend == 'down' ? Colors.green : trend == 'up' ? Colors.red : Colors.grey,
              ),
              Text(
                '${trendValue!.abs().toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Clean Material 3 badge widget for vehicle status tags.
class StatusBadge extends StatelessWidget {
  final VehicleStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 13,
            color: status.color,
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


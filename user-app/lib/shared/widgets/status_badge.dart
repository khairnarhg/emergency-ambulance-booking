import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize});

  Color get color {
    switch (status) {
      case 'CREATED':
      case 'DISPATCHING':
        return AppColors.statusCreated;
      case 'AMBULANCE_ASSIGNED':
      case 'DRIVER_ENROUTE_TO_PATIENT':
        return AppColors.statusEnroute;
      case 'REACHED_PATIENT':
      case 'PICKED_UP':
      case 'ENROUTE_TO_HOSPITAL':
        return AppColors.statusPickedUp;
      case 'ARRIVED_AT_HOSPITAL':
      case 'COMPLETED':
        return AppColors.statusCompleted;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      default:
        return AppColors.textTertiary;
    }
  }

  String get label {
    switch (status) {
      case 'CREATED':
        return 'Created';
      case 'DISPATCHING':
        return 'Dispatching';
      case 'AMBULANCE_ASSIGNED':
        return 'Assigned';
      case 'DRIVER_ENROUTE_TO_PATIENT':
        return 'En Route';
      case 'REACHED_PATIENT':
        return 'Reached You';
      case 'PICKED_UP':
        return 'Picked Up';
      case 'ENROUTE_TO_HOSPITAL':
        return 'To Hospital';
      case 'ARRIVED_AT_HOSPITAL':
        return 'At Hospital';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class CriticalityBadge extends StatelessWidget {
  final String criticality;

  const CriticalityBadge({super.key, required this.criticality});

  Color get color {
    switch (criticality) {
      case 'LOW':
        return AppColors.criticalityLow;
      case 'MEDIUM':
        return AppColors.criticalityMedium;
      case 'HIGH':
        return AppColors.criticalityHigh;
      case 'CRITICAL':
        return AppColors.criticalityCritical;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        criticality,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// Horizontal status timeline
class SosStatusTimeline extends StatelessWidget {
  final String currentStatus;

  const SosStatusTimeline({super.key, required this.currentStatus});

  static const _statuses = [
    ('CREATED', 'Created'),
    ('DISPATCHING', 'Dispatching'),
    ('AMBULANCE_ASSIGNED', 'Assigned'),
    ('DRIVER_ENROUTE_TO_PATIENT', 'En Route'),
    ('REACHED_PATIENT', 'Reached'),
    ('PICKED_UP', 'Picked Up'),
    ('ENROUTE_TO_HOSPITAL', 'To Hospital'),
    ('ARRIVED_AT_HOSPITAL', 'At Hospital'),
    ('COMPLETED', 'Done'),
  ];

  int get _currentIndex {
    final idx =
        _statuses.indexWhere((s) => s.$1 == currentStatus);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: StatusBadge(status: 'CANCELLED', fontSize: 14),
        ),
      );
    }

    final currentIdx = _currentIndex;

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statuses.length,
        itemBuilder: (context, i) {
          final (status, label) = _statuses[i];
          final isPast = i < currentIdx;
          final isCurrent = i == currentIdx;
          final isFuture = i > currentIdx;

          Color dotColor;
          if (isPast) {
            dotColor = AppColors.success;
          } else if (isCurrent) {
            dotColor = AppColors.primary;
          } else {
            dotColor = AppColors.divider;
          }

          return Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 14 : 10,
                    height: isCurrent ? 14 : 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(77),
                                blurRadius: 6,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 64,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isCurrent
                            ? AppColors.primary
                            : isFuture
                                ? AppColors.textTertiary
                                : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              if (i < _statuses.length - 1)
                Container(
                  width: 16,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: isPast ? AppColors.success : AppColors.divider,
                ),
            ],
          );
        },
      ),
    );
  }
}

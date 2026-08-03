import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

class NextCareBadge extends StatelessWidget {
  final Plant plant;

  const NextCareBadge({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final nextWater = plant.nextWaterDate;
    final nextFertilize = plant.nextFertilizeDate;
    final nextMist = plant.nextMistDate;

    final now = DateTime.now();
    DateTime? nearest;
    String careType = '';

    void check(DateTime? date, String type) {
      if (date == null) return;
      if (nearest == null || date.isBefore(nearest!)) {
        nearest = date;
        careType = type;
      }
    }

    check(nextWater, 'Water');
    check(nextFertilize, 'Fertilize');
    check(nextMist, 'Mist');

    if (nearest == null) {
      return _Badge(
        text: 'No schedule',
        backgroundColor: AppColors.bgTertiary,
        textColor: AppColors.textTertiary,
      );
    }

    final isOverdue = nearest!.isBefore(now);
    final diff = nearest!.difference(now).inDays;

    if (isOverdue) {
      return _Badge(
        text: '$careType overdue',
        backgroundColor: AppColors.error.withOpacity(0.12),
        textColor: AppColors.error,
      );
    }

    if (diff == 0) {
      return _Badge(
        text: '$careType today',
        backgroundColor: AppColors.warning.withOpacity(0.12),
        textColor: AppColors.warning,
      );
    }

    return _Badge(
      text: '$careType in $diff days',
      backgroundColor: AppColors.accent.withOpacity(0.12),
      textColor: AppColors.accent,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _Badge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../utils/constants.dart';

class NextCareBadge extends StatelessWidget {
  final Plant plant;

  const NextCareBadge({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    // FIX: original source only checked water/fertilize/mist. This
    // predates Fix Phase A's addition of repot/prune/treat scheduling
    // to plant_model.dart/plant_provider.dart, and was never updated
    // to match — meaning this badge (shown on every plant card, room
    // card, and the care schedule screen) would silently ignore any
    // upcoming/overdue repot, prune, or treat care. Now checks all 6,
    // matching plant_provider.dart's own _scheduleRemindersForPlant.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final nextWater = plant.nextWaterDate;
    final nextFertilize = plant.nextFertilizeDate;
    final nextMist = plant.nextMistDate;
    final nextRepot = plant.nextRepotDate;
    final nextPrune = plant.nextPruneDate;
    final nextTreat = plant.nextTreatDate;

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
    check(nextRepot, 'Repot');
    check(nextPrune, 'Prune');
    check(nextTreat, 'Treat');

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
        textColor: dark ? AppColors.errorDark : AppColors.error,
      );
    }

    if (diff == 0) {
      return _Badge(
        text: '$careType today',
        backgroundColor: AppColors.warning.withOpacity(0.16),
        textColor: dark ? AppColors.warningDark : AppColors.watchText,
      );
    }

    return _Badge(
      text: '$careType in $diff days',
      backgroundColor: AppColors.accent.withOpacity(0.12),
      textColor: dark ? AppColors.accentLight : AppColors.accent,
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

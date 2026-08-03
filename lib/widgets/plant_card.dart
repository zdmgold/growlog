import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'next_care_badge.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumb = plant.latestPhoto;

    return Semantics(
      label: '${plant.name} plant card',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.lg),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumb != null && File(thumb.path).existsSync())
                        Image.file(
                          File(thumb.path),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
                          child: Icon(
                            Icons.local_florist,
                            color: AppColors.textTertiary,
                            size: 40,
                          ),
                        ),
                      if (plant.isOverdue)
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: const Text(
                              'Overdue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: AppTypography.title2.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (plant.species != null)
                      Text(
                        plant.species!,
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    NextCareBadge(plant: plant),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

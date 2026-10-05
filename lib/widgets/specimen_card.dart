import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import 'next_care_badge.dart';
import 'plant_thumb.dart';

/// A plant presented like a herbarium label: photo, serif name, italic species.
class SpecimenCard extends StatelessWidget {
  final Plant plant;
  final PlantProvider plantProvider;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const SpecimenCard({
    super.key,
    required this.plant,
    required this.plantProvider,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final hasPhoto = plant.latestPhoto != null;
    final species = plant.species?.trim() ?? '';

    final photo = PlantThumb(plant: plant, plantProvider: plantProvider);

    return Semantics(
      button: true,
      label: '${plant.name}, open plant',
      child: Material(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color:
                    isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
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
                    child: SizedBox(
                      width: double.infinity,
                      child: hasPhoto
                          ? Hero(tag: 'plant_${plant.id}', child: photo)
                          : photo,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title1.copyWith(
                          color: ink,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        species.isEmpty ? 'Species not set' : species,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.latin.copyWith(color: sub),
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
      ),
    );
  }
}

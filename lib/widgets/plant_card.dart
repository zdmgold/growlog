import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'next_care_badge.dart';
import 'skeleton_loader.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  // SURGICAL ADDITION: needed to read the async image-existence cache
  // (feature #5) instead of calling File(path).existsSync() directly
  // in build(), which was a synchronous disk read on every rebuild.
  final PlantProvider plantProvider;

  const PlantCard({
    super.key,
    required this.plant,
    required this.onTap,
    required this.plantProvider,
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
              color: isDark
                  ? AppColors.borderSubtleDark
                  : AppColors.borderSubtle,
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
                      _buildThumbnail(thumb, isDark),
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
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
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

  /// SURGICAL FIX: previously did
  /// `if (thumb != null && File(thumb.path).existsSync())` directly in
  /// build() — a blocking disk stat on every single rebuild/scroll pass
  /// of every visible card. Now:
  ///   - null cache entry (not checked yet)  -> SkeletonLoader (feature #1)
  ///   - true                                -> the actual image, wrapped
  ///     in a Hero so plant_detail_screen's destination Hero animates
  ///     from here (feature #4)
  ///   - false / no photo                    -> the placeholder icon
  Widget _buildThumbnail(dynamic thumb, bool isDark) {
    if (thumb == null) {
      return _placeholder(isDark);
    }

    final exists = plantProvider.imageExists(thumb.path);
    if (exists == null) {
      return const SkeletonLoader();
    }
    if (exists == false) {
      return _placeholder(isDark);
    }

    return Hero(
      tag: 'plant_${plant.id}',
      child: Image.file(
        File(thumb.path),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
      child: const Icon(
        Icons.local_florist,
        color: AppColors.textTertiary,
        size: 40,
      ),
    );
  }
}

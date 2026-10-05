import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import 'skeleton_loader.dart';

/// A plant's latest photo, or a botanical placeholder. No Hero here so it is
/// safe to show the same plant in several places on one screen.
class PlantThumb extends StatelessWidget {
  final Plant plant;
  final PlantProvider plantProvider;

  const PlantThumb({
    super.key,
    required this.plant,
    required this.plantProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumb = plant.latestPhoto;
    if (thumb == null) return _placeholder(isDark);
    final exists = plantProvider.imageExists(thumb.path);
    if (exists == null) return const SkeletonLoader();
    if (exists == false) return _placeholder(isDark);
    return Image.file(
      File(thumb.path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(isDark),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
      alignment: Alignment.center,
      child: Icon(
        PhosphorRegular.leaf,
        size: 34,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
    );
  }
}

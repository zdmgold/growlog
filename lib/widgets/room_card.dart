import 'dart:io';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import 'skeleton_loader.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final List<Plant> plants;
  final VoidCallback onTap;
  // SURGICAL ADDITION: needed to read the async image-existence cache
  // instead of File(path).existsSync() in the photo grid below.
  final PlantProvider plantProvider;

  const RoomCard({
    super.key,
    required this.room,
    required this.plants,
    required this.onTap,
    required this.plantProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewPhotos = plants
        .where((p) => p.latestPhoto != null)
        .take(4)
        .map((p) => p.latestPhoto!.path)
        .toList();

    return Semantics(
      label: '${room.name}, ${plants.length} plants',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark
                  ? AppColors.borderSubtleDark
                  : AppColors.borderSubtle,
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
                  child: previewPhotos.isEmpty
                      ? Container(
                          color: isDark
                              ? AppColors.bgTertiaryDark
                              : AppColors.bgTertiary,
                          child: Center(
                            child: Icon(
                              PhosphorRegular.house,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                              size: 34,
                            ),
                          ),
                        )
                      : _PhotoGrid(
                          photos: previewPhotos,
                          plantProvider: plantProvider,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: AppTypography.title1.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${plants.length} ${plants.length == 1 ? 'plant' : 'plants'}',
                      style: AppTypography.footnote.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
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

class _PhotoGrid extends StatelessWidget {
  final List<String> photos;
  final PlantProvider plantProvider;

  const _PhotoGrid({required this.photos, required this.plantProvider});

  @override
  Widget build(BuildContext context) {
    if (photos.length == 1) {
      return _buildImage(photos[0], fit: BoxFit.cover);
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildImage(photos[0])),
              if (photos.length > 1) ...[
                const SizedBox(width: 2),
                Expanded(child: _buildImage(photos[1])),
              ],
            ],
          ),
        ),
        if (photos.length > 2) ...[
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImage(photos[2])),
                if (photos.length > 3) ...[
                  const SizedBox(width: 2),
                  Expanded(child: _buildImage(photos[3])),
                ] else ...[
                  const SizedBox(width: 2),
                  Expanded(child: Container(color: Colors.black12)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// SURGICAL FIX: previously called `File(path).existsSync()` directly
  /// during build. Now reads the async cache: null (not checked yet)
  /// shows a SkeletonLoader, false shows the same black12 placeholder
  /// as before, true shows the image.
  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    final exists = plantProvider.imageExists(path);
    if (exists == null) {
      return const SkeletonLoader(borderRadius: BorderRadius.zero);
    }
    if (exists == false) {
      return Container(color: Colors.black12);
    }
    return Image.file(File(path), fit: fit);
  }
}

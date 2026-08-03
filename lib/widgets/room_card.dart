import 'dart:io';
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/plant_model.dart';
import '../utils/constants.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final List<Plant> plants;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.plants,
    required this.onTap,
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
                  child: previewPhotos.isEmpty
                      ? Container(
                          color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
                          child: Center(
                            child: Icon(
                              Icons.meeting_room,
                              color: AppColors.textTertiary,
                              size: 32,
                            ),
                          ),
                        )
                      : _PhotoGrid(photos: previewPhotos),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: AppTypography.title2.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${plants.length} ${plants.length == 1 ? 'plant' : 'plants'}',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.textTertiary,
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
  const _PhotoGrid({required this.photos});

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

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: fit);
    }
    return Container(color: Colors.black12);
  }
}

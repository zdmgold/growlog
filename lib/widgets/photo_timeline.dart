import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_entry_model.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

class PhotoTimeline extends StatelessWidget {
  final List<PhotoEntry> photos;
  final Function(PhotoEntry)? onTap;

  const PhotoTimeline({
    super.key,
    required this.photos,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No photos yet',
              style: AppTypography.callout.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isFirst = index == 0;

        return Semantics(
          label: 'Photo from ${DateFormatter.dateOnly(photo.date)}',
          child: GestureDetector(
            onTap: onTap != null ? () => onTap!(photo) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
                            width: 2,
                          ),
                        ),
                      ),
                      if (!isFirst)
                        Container(width: 2, height: 80, color: AppColors.borderSubtle),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
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
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadii.lg),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: File(photo.path).existsSync()
                                  ? Image.file(File(photo.path), fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.bgTertiary,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormatter.dateTime(photo.date),
                                  style: AppTypography.footnote.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                if (photo.notes != null && photo.notes!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    photo.notes!,
                                    style: AppTypography.body.copyWith(
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                                if (photo.height != null || photo.leafCount != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    children: [
                                      if (photo.height != null)
                                        _MetricChip(label: '${photo.height} cm'),
                                      if (photo.leafCount != null)
                                        _MetricChip(label: '${photo.leafCount} leaves'),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  const _MetricChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

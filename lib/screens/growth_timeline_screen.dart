import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/plant_model.dart';
import '../models/photo_entry_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../widgets/growth_slider.dart';
import '../services/export_service.dart';

class GrowthTimelineScreen extends StatefulWidget {
  final Plant plant;
  // SURGICAL ADDITION: required to thread through to GrowthSlider,
  // which now needs plantProvider for its async image-existence cache
  // (Fix Phase B, feature #5).
  final PlantProvider plantProvider;

  const GrowthTimelineScreen({
    super.key,
    required this.plant,
    required this.plantProvider,
  });

  @override
  State<GrowthTimelineScreen> createState() => _GrowthTimelineScreenState();
}

class _GrowthTimelineScreenState extends State<GrowthTimelineScreen> {
  late PhotoEntry _before;
  late PhotoEntry _after;
  final GlobalKey _sliderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final sorted = List<PhotoEntry>.from(widget.plant.photos)
      ..sort((a, b) => a.date.compareTo(b.date));
    _before = sorted.first;
    _after = sorted.last;
  }

  Future<void> _export() async {
    final boundary =
        _sliderKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await ExportService.captureWidget(boundary);
    if (image != null && mounted) {
      await ExportService.shareImage(
        image,
        text: '${widget.plant.name} growth — tracked with GrowLog',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.plant.name,
          style: AppTypography.title1.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _export,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: RepaintBoundary(
                key: _sliderKey,
                child: GrowthSlider(
                  before: _before,
                  after: _after,
                  plantProvider: widget.plantProvider,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.xl),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Text(
                    'Drag the slider to compare growth',
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Before',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            DateFormatter.dateOnly(_before.date),
                            style: AppTypography.body.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'After',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            DateFormatter.dateOnly(_after.date),
                            style: AppTypography.body.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plant_model.dart';
import '../models/care_log_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../widgets/care_quick_actions.dart';
import '../widgets/growth_stats.dart';
import '../widgets/measurement_chart.dart';
import '../widgets/photo_timeline.dart';
import '../widgets/skeleton_loader.dart';
import 'growth_timeline_screen.dart';
import 'add_plant_screen.dart';
import 'paul_chat_screen.dart';
import '../services/ai/ai_settings.dart';
import 'ai_setup_screen.dart';
import 'camera_screen.dart';
import 'scan_screen.dart';

class PlantDetailScreen extends StatelessWidget {
  final PlantProvider plantProvider;
  final String plantId;

  const PlantDetailScreen({
    super.key,
    required this.plantProvider,
    required this.plantId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: plantProvider,
      builder: (context, _) {
        final plant = plantProvider.getPlant(plantId);
        if (plant == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Plant not found',
                style: AppTypography.body.copyWith(color: AppColors.textTertiary),
              ),
            ),
          );
        }

        final latestPhoto = plant.latestPhoto;

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroBackground(latestPhoto, plant.id),
                ),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Navigate to edit
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context, plant),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: AppTypography.headline.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      if (plant.species != null)
                        Text(
                          plant.species!,
                          style: AppTypography.body.copyWith(color: AppColors.textTertiary),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Acquired ${DateFormatter.relative(plant.acquiredDate)}',
                        style: AppTypography.footnote.copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CareQuickActions(
                        onCareLogged: (type) => _logCare(context, plant, type),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (plant.measurements.length >= 2) ...[
                        GrowthStats(measurements: plant.measurements),
                        const SizedBox(height: AppSpacing.lg),
                        MeasurementChart(
                          measurements: plant.measurements,
                          title: 'Height Trend',
                          showHeight: true,
                          showLeafCount: false,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _openGrowthTimeline(context, plant),
                          icon: const Icon(Icons.compare_arrows),
                          label: const Text(
                            'View Growth Timeline',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Photos',
                            style: AppTypography.title1.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _addPhoto(context, plant),
                            child: const Text('Add Photo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 200,
                        child: PhotoTimeline(
                          photos: plant.photos.take(5).toList(),
                          plantProvider: plantProvider,
                          onTap: (photo) => _openGrowthTimeline(context, plant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBackground(dynamic latestPhoto, String plantId) {
    if (latestPhoto == null) {
      return _placeholderHero();
    }

    final exists = plantProvider.imageExists(latestPhoto.path);
    if (exists == null) {
      return const SkeletonLoader(borderRadius: BorderRadius.zero);
    }
    if (exists == false) {
      return _placeholderHero();
    }

    return Hero(
      tag: 'plant_$plantId',
      child: Image.file(
        File(latestPhoto.path),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _placeholderHero() {
    return Container(
      color: AppColors.accent.withOpacity(0.1),
      child: const Icon(
        Icons.local_florist,
        size: 80,
        color: AppColors.accent,
      ),
    );
  }

  void _logCare(BuildContext context, Plant plant, CareType type) {
    HapticFeedback.mediumImpact();
    final log = CareLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plantId: plant.id,
      type: type,
      date: DateTime.now(),
    );
    plantProvider.addCareLog(plant.id, log);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${type.label} logged for ${plant.name}')),
    );
  }

  void _openGrowthTimeline(BuildContext context, Plant plant) {
    if (plant.photos.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 photos to see growth timeline')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GrowthTimelineScreen(
          plant: plant,
          plantProvider: plantProvider,
        ),
      ),
    );
  }

  void _addPhoto(BuildContext context, Plant plant) {
    // Image picker logic would go here
  }

  /// Doctor: take a photo of this plant and check its health. The result is
  /// kept in the plant's history.
  Future<void> _startDoctor(BuildContext context, Plant plant) async {
    if (!AiSettings.instance.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add your API key to check plant health.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiSetupScreen()),
      );
      return;
    }
    final result = await Navigator.push<CameraResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CameraScreen(),
      ),
    );
    if (result == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          plantProvider: plantProvider,
          imagePath: result.path,
          plant: plant,
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, Plant plant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.bgSecondaryDark
                : AppColors.bgSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Photos'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.eco, color: AppColors.accent),
                title: const Text('Ask Paul about this plant'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaulChatScreen(
                        plantProvider: plantProvider,
                        plant: plant,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety, color: AppColors.accent),
                title: const Text('Doctor: check health'),
                onTap: () {
                  Navigator.pop(context);
                  _startDoctor(context, plant);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive),
                title: Text(plant.isDead ? 'Revive Plant' : 'Mark as Dead'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  plantProvider.toggleDead(plant.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Plant?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            plantProvider.deletePlant(plant.id);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

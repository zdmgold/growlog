import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/care_log_model.dart';
import '../models/photo_entry_model.dart';
import '../models/plant_model.dart';
import '../models/scan_record.dart';
import '../providers/plant_provider.dart';
import '../services/ai/ai_settings.dart';
import '../services/scan_store.dart';
import '../utils/care_due.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/phosphor_icons.dart';
import '../utils/image_prep.dart';
import '../widgets/ad_slot.dart';
import '../widgets/care_today_row.dart' show careIcon;
import '../widgets/motion_widgets.dart';
import '../widgets/scan_widgets.dart';
import '../widgets/skeleton_loader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'ai_setup_screen.dart';
import 'camera_screen.dart';
import 'paul_chat_screen.dart';
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
            appBar: AppBar(),
            body: Center(
              child: Text(
                'Plant not found',
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiary,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
          bottomNavigationBar: const SafeArea(top: false, child: AdSlot()),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor:
                    isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
                surfaceTintColor: Colors.transparent,
                leadingWidth: 64,
                leading: _RoundButton(
                  icon: PhosphorBold.arrowLeft,
                  label: 'Back',
                  isDark: isDark,
                  onTap: () => Navigator.pop(context),
                ),
                actions: [
                  _RoundButton(
                    icon: PhosphorBold.dotsThree,
                    label: 'More options',
                    isDark: isDark,
                    onTap: () => _showOptions(context, plant),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHero(plant, isDark),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.55, 1.0],
                            colors: [
                              Colors.black.withOpacity(0.18),
                              Colors.transparent,
                              (isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary)
                                  .withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _Body(
                  plant: plant,
                  plantProvider: plantProvider,
                  onLogCare: (type) => _logCare(context, plant, type),
                  onDoctor: () => _startDoctor(context, plant),
                  onEditSchedule: () => _showSchedule(context, plant),
                  onAddPhoto: () => _addPhotoUpdate(context, plant),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(Plant plant, bool isDark) {
    final photo = plant.latestPhoto;
    if (photo == null) return _placeholderHero(isDark);
    final exists = plantProvider.imageExists(photo.path);
    if (exists == null) return const SkeletonLoader(borderRadius: BorderRadius.zero);
    if (exists == false) return _placeholderHero(isDark);
    return Hero(
      tag: 'plant_${plant.id}',
      child: Image.file(File(photo.path), fit: BoxFit.cover),
    );
  }

  Widget _placeholderHero(bool isDark) {
    return Container(
      color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
      alignment: Alignment.center,
      child: Icon(
        PhosphorFill.leaf,
        size: 80,
        color: isDark ? AppColors.accentLight : AppColors.accent,
      ),
    );
  }

  void _logCare(BuildContext context, Plant plant, CareType type) {
    HapticFeedback.mediumImpact();
    final log = CareLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      plantId: plant.id,
      type: type,
      date: DateTime.now(),
    );
    plantProvider.addCareLog(plant.id, log);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${type.label} logged for ${plant.name}')),
    );
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

  /// Adds a plain photo to the plant's growth record. No AI, no key needed.
  Future<void> _addPhotoUpdate(BuildContext context, Plant plant) async {
    final result = await Navigator.push<CameraResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CameraScreen(),
      ),
    );
    if (result == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await compute(prepareImageForAi, result.path);
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/plant_${const Uuid().v4()}.jpg';
      await File(path).writeAsBytes(bytes);
      await plantProvider.addPhoto(
        plant.id,
        PhotoEntry(
          id: const Uuid().v4(),
          plantId: plant.id,
          date: DateTime.now(),
          path: path,
          notes: 'Photo update',
        ),
      );
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(content: Text('Photo added to ${plant.name}')),
      );
    } catch (e) {
      debugPrint('Add photo update error: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not save that photo. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSchedule(BuildContext context, Plant plant) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleSheet(
        plantId: plant.id,
        plantProvider: plantProvider,
      ),
    );
  }

  void _showOptions(BuildContext context, Plant plant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final err = isDark ? AppColors.errorDark : AppColors.error;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(PhosphorRegular.chatCircleDots, color: accent),
                title: const Text('Ask Paul about this plant'),
                onTap: () {
                  Navigator.pop(sheetContext);
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
                leading: Icon(PhosphorRegular.calendarCheck, color: accent),
                title: const Text('Edit care schedule'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSchedule(context, plant);
                },
              ),
              ListTile(
                leading: Icon(PhosphorRegular.stethoscope, color: accent),
                title: const Text('Doctor: check health'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startDoctor(context, plant);
                },
              ),
              ListTile(
                leading: const Icon(PhosphorRegular.leaf),
                title: Text(plant.isDead ? 'Revive plant' : 'Mark as dead'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  plantProvider.toggleDead(plant.id);
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: Icon(PhosphorRegular.trash, color: err),
                title: Text('Delete', style: TextStyle(color: err)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete plant?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            plantProvider.deletePlant(plant.id);
                            Navigator.pop(dialogContext);
                            Navigator.pop(context);
                          },
                          child: Text('Delete', style: TextStyle(color: err)),
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

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: (isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary)
              .withOpacity(0.92),
          shape: CircleBorder(
            side: BorderSide(
              color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Plant plant;
  final PlantProvider plantProvider;
  final void Function(CareType) onLogCare;
  final VoidCallback onDoctor;
  final VoidCallback onEditSchedule;
  final VoidCallback onAddPhoto;

  const _Body({
    required this.plant,
    required this.plantProvider,
    required this.onLogCare,
    required this.onDoctor,
    required this.onEditSchedule,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final species = plant.species?.trim() ?? '';
    final scheduled = [
      for (final t in CareType.values)
        if (nextCareDate(plant, t) != null) t,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plant.name, style: AppTypography.display.copyWith(color: ink)),
          if (species.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                species,
                style: AppTypography.latin.copyWith(color: sub, fontSize: 16),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: ScanStore.instance,
            builder: (context, _) {
              final scans = _plantScans();
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (scans.isNotEmpty) ScanHealthPill(health: scans.first.health),
                  Text(
                    'Added ${DateFormatter.relative(plant.acquiredDate).toLowerCase()}',
                    style: AppTypography.footnote.copyWith(color: sub),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            title: 'Care',
            action: 'Edit schedule',
            onAction: onEditSchedule,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (scheduled.isEmpty)
            _EmptyNote(
              isDark: isDark,
              text: 'No care schedule yet. Tap Edit schedule to add one.',
            )
          else
            for (final t in scheduled)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _CareRow(
                  plant: plant,
                  type: t,
                  isDark: isDark,
                  onDone: () => onLogCare(t),
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          Text('Log care now',
              style: AppTypography.caption.copyWith(color: sub)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in CareType.values)
                _LogChip(type: t, isDark: isDark, onTap: () => onLogCare(t)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            title: 'Growth',
            action: 'Add photo',
            onAction: onAddPhoto,
          ),
          const SizedBox(height: AppSpacing.sm),
          _GrowthSection(plant: plant, plantProvider: plantProvider, isDark: isDark),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(title: 'Doctor'),
          const SizedBox(height: AppSpacing.sm),
          _DoctorCard(
            plant: plant,
            plantProvider: plantProvider,
            isDark: isDark,
            onDoctor: onDoctor,
          ),
          if (plant.notes != null && plant.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(title: 'Notes'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              plant.notes!,
              style: AppTypography.body.copyWith(color: ink),
            ),
          ],
        ],
      ),
    );
  }

  List<ScanRecord> _plantScans() {
    return ScanStore.instance.scans
        .where((s) =>
            s.isPlant && (s.plantId == plant.id || s.savedPlantId == plant.id))
        .toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.title1.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final bool isDark;
  final String text;
  const _EmptyNote({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.footnote.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  final Plant plant;
  final CareType type;
  final bool isDark;
  final VoidCallback onDone;

  const _CareRow({
    required this.plant,
    required this.type,
    required this.isDark,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final next = nextCareDate(plant, type)!;
    final due = DueCare(plant: plant, type: type, due: next);
    final overdue = due.isOverdue;
    final status = overdue
        ? 'Overdue ${due.daysLate} days'
        : due.daysUntil <= 0
            ? 'Due today'
            : due.daysUntil == 1
                ? 'Due tomorrow'
                : 'In ${due.daysUntil} days';
    final statusColor = overdue
        ? (isDark ? AppColors.errorDark : AppColors.attention)
        : due.daysUntil <= 0
            ? (isDark ? AppColors.warningDark : AppColors.watchText)
            : sub;
    final freq = careFrequency(plant, type);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(careIcon(type), size: 22, color: type.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.label,
                    style: AppTypography.title2.copyWith(color: ink)),
                const SizedBox(height: 2),
                Text(
                  freq == null ? status : '$status · every $freq days',
                  style: AppTypography.footnote.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          DoneCheckButton(
            type: type,
            size: 44,
            semanticLabel: 'Mark ${type.label} done',
            background: isDark ? AppColors.accentLight : AppColors.accent,
            foreground: isDark ? AppColors.bgPrimaryDark : Colors.white,
            onDone: onDone,
          ),
        ],
      ),
    );
  }
}

class _LogChip extends StatelessWidget {
  final CareType type;
  final bool isDark;
  final VoidCallback onTap;
  const _LogChip({required this.type, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Log ${type.label}',
      child: Material(
        color: type.color.withOpacity(0.12),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(careIcon(type), size: 18, color: type.color),
                const SizedBox(width: 8),
                Text(
                  type.label,
                  style: AppTypography.callout.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
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

class _DoctorCard extends StatelessWidget {
  final Plant plant;
  final PlantProvider plantProvider;
  final bool isDark;
  final VoidCallback onDoctor;

  const _DoctorCard({
    required this.plant,
    required this.plantProvider,
    required this.isDark,
    required this.onDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
        ),
      ),
      child: ListenableBuilder(
        listenable: ScanStore.instance,
        builder: (context, _) {
          final scans = ScanStore.instance.scans
              .where((s) =>
                  s.isPlant &&
                  (s.plantId == plant.id || s.savedPlantId == plant.id))
              .take(8)
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Take a photo and check how ${plant.name} is doing. Each check is kept here.',
                style: AppTypography.footnote.copyWith(color: sub),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onDoctor,
                  icon: const Icon(PhosphorFill.camera, size: 20),
                  label: const Text('Check health'),
                ),
              ),
              if (scans.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('History', style: AppTypography.caption.copyWith(color: sub)),
                const SizedBox(height: AppSpacing.sm),
                for (final s in scans)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanScreen(
                          plantProvider: plantProvider,
                          record: s,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: ScanThumb(scan: s),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.hasIssue ? s.issue : 'Looking healthy',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.title2.copyWith(
                                    color: ink,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ScanHealthPill(health: s.health, compact: true),
                                    const SizedBox(width: 8),
                                    Text(
                                      scanDateLabel(context, s.createdAt),
                                      style: AppTypography.caption
                                          .copyWith(color: sub),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(PhosphorBold.caretRight, size: 16, color: sub),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

const Map<CareType, int> _defaultDays = {
  CareType.water: 7,
  CareType.fertilize: 30,
  CareType.mist: 3,
  CareType.repot: 365,
  CareType.prune: 90,
  CareType.treat: 14,
};

/// Change how often each kind of care repeats, or turn one off.
class _ScheduleSheet extends StatelessWidget {
  final String plantId;
  final PlantProvider plantProvider;
  const _ScheduleSheet({required this.plantId, required this.plantProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        child: ListenableBuilder(
          listenable: plantProvider,
          builder: (context, _) {
            final plant = plantProvider.getPlant(plantId);
            if (plant == null) return const SizedBox.shrink();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sub.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Care schedule',
                    style: AppTypography.title1.copyWith(color: ink)),
                const SizedBox(height: 2),
                Text(
                  'How many days between each kind of care. Reminders follow this.',
                  style: AppTypography.footnote.copyWith(color: sub),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final t in CareType.values)
                  _ScheduleRow(
                    type: t,
                    days: careFrequency(plant, t),
                    isDark: isDark,
                    onChanged: (d) {
                      HapticFeedback.selectionClick();
                      plantProvider.updatePlant(withCareFrequency(plant, t, d));
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final CareType type;
  final int? days;
  final bool isDark;
  final ValueChanged<int?> onChanged;

  const _ScheduleRow({
    required this.type,
    required this.days,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final d = days;

    Widget stepButton(IconData icon, String label, VoidCallback onTap) {
      return Semantics(
        button: true,
        label: label,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: type.color.withOpacity(0.12),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(careIcon(type), size: 20, color: type.color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(type.label, style: AppTypography.title2.copyWith(color: ink)),
          ),
          if (d == null)
            TextButton(
              onPressed: () => onChanged(_defaultDays[type]),
              child: const Text('Add'),
            )
          else ...[
            stepButton(PhosphorBold.caretLeft, 'Fewer days for ${type.label}', () {
              if (d <= 1) {
                onChanged(null);
              } else {
                onChanged(d - 1);
              }
            }),
            SizedBox(
              width: 74,
              child: Text(
                'every $d d',
                textAlign: TextAlign.center,
                style: AppTypography.callout.copyWith(color: sub),
              ),
            ),
            stepButton(PhosphorBold.caretRight, 'More days for ${type.label}', () {
              if (d < 365) onChanged(d + 1);
            }),
          ],
        ],
      ),
    );
  }
}


String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// Before and after of the oldest and newest photo, plus every photo by date.
class _GrowthSection extends StatelessWidget {
  final Plant plant;
  final PlantProvider plantProvider;
  final bool isDark;

  const _GrowthSection({
    required this.plant,
    required this.plantProvider,
    required this.isDark,
  });

  Widget _image(PhotoEntry p, {BoxFit fit = BoxFit.cover}) {
    return Image.file(
      File(p.path),
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
        alignment: Alignment.center,
        child: Icon(
          PhosphorRegular.leaf,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
      ),
    );
  }

  void _open(BuildContext context, PhotoEntry p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(photo: p, plantName: plant.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final photos = [...plant.photos]..sort((a, b) => a.date.compareTo(b.date));

    if (photos.length < 2) {
      return _EmptyNote(
        isDark: isDark,
        text: 'Add a photo now and another later to see how '
            '${plant.name} grows. Tap Add photo.',
      );
    }

    final first = photos.first;
    final last = photos.last;
    final days = last.date.difference(first.date).inDays;

    Widget half(PhotoEntry p, String label) {
      return Expanded(
        child: GestureDetector(
          onTap: () => _open(context, p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: _image(p),
                ),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTypography.callout.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  )),
              Text(_shortDate(p.date),
                  style: AppTypography.caption.copyWith(color: sub)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              half(first, 'First'),
              const SizedBox(width: AppSpacing.md),
              half(last, 'Latest'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            days <= 0
                ? '${photos.length} photos'
                : '${photos.length} photos over $days ${days == 1 ? 'day' : 'days'}',
            style: AppTypography.footnote.copyWith(color: sub),
          ),
          if (photos.length > 2) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final p = photos[i];
                  return GestureDetector(
                    onTap: () => _open(context, p),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: SizedBox(width: 72, height: 72, child: _image(p)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.date.month}/${p.date.day}',
                          style: AppTypography.caption.copyWith(color: sub),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final PhotoEntry photo;
  final String plantName;
  const _PhotoViewer({required this.photo, required this.plantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '$plantName · ${_shortDate(photo.date)}',
          style: AppTypography.callout.copyWith(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.file(
            File(photo.path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              PhosphorRegular.leaf,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

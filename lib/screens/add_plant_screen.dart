import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:growlog/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/care_log_model.dart';
import '../models/photo_entry_model.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../services/interstitial_service.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import '../widgets/ad_slot.dart';
import '../widgets/care_today_row.dart' show careIcon;
import 'camera_screen.dart';

/// Add a plant by hand. Care schedules are opt-in: only watering and feeding
/// start switched on, so a new plant is not buried in tasks.
class AddPlantScreen extends StatefulWidget {
  final PlantProvider plantProvider;

  const AddPlantScreen({super.key, required this.plantProvider});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _notesController = TextEditingController();

  static const Map<CareType, int> _defaultDays = {
    CareType.water: 7,
    CareType.fertilize: 30,
    CareType.mist: 3,
    CareType.repot: 365,
    CareType.prune: 90,
    CareType.treat: 14,
  };

  late final Map<CareType, TextEditingController> _days = {
    for (final t in CareType.values)
      t: TextEditingController(text: '${_defaultDays[t]}'),
  };
  final Map<CareType, bool> _on = {
    CareType.water: true,
    CareType.fertilize: true,
    CareType.mist: false,
    CareType.repot: false,
    CareType.prune: false,
    CareType.treat: false,
  };

  String? _selectedRoomId;
  File? _photoFile;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _notesController.dispose();
    for (final c in _days.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await Navigator.push<CameraResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CameraScreen(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _photoFile = File(result.path));
    }
  }

  int? _freq(CareType t) {
    if (_on[t] != true) return null;
    final n = int.tryParse(_days[t]!.text.trim());
    if (n == null || n < 1) return _defaultDays[t];
    return n > 3650 ? 3650 : n;
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      _showError(l10n?.plantNameRequired ?? 'Plant name is required');
      return;
    }
    setState(() => _saving = true);

    try {
      String? photoPath;
      if (_photoFile != null) {
        final dir = await getApplicationDocumentsDirectory();
        photoPath = '${dir.path}/plant_${const Uuid().v4()}.jpg';
        await _photoFile!.copy(photoPath);
      }

      final plantId = const Uuid().v4();
      final now = DateTime.now();
      final plant = Plant(
        id: plantId,
        name: _nameController.text.trim(),
        species: _speciesController.text.trim().isEmpty
            ? null
            : _speciesController.text.trim(),
        roomId: _selectedRoomId,
        acquiredDate: now,
        photos: photoPath != null
            ? [
                PhotoEntry(
                  id: const Uuid().v4(),
                  plantId: plantId,
                  date: now,
                  path: photoPath,
                ),
              ]
            : [],
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        waterFrequencyDays: _freq(CareType.water),
        fertilizeFrequencyDays: _freq(CareType.fertilize),
        mistFrequencyDays: _freq(CareType.mist),
        repotFrequencyDays: _freq(CareType.repot),
        pruneFrequencyDays: _freq(CareType.prune),
        treatFrequencyDays: _freq(CareType.treat),
        createdAt: now,
      );

      await widget.plantProvider.addPlant(plant);
      HapticFeedback.mediumImpact();
      // Interstitial point 3: a plant saved by hand is a finished task.
      await InterstitialService.afterTask();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('AddPlantScreen._save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        _showError('Could not save the plant. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _label(CareType t, AppLocalizations? l10n) {
    switch (t) {
      case CareType.water:
        return l10n?.waterEvery ?? 'Water every';
      case CareType.fertilize:
        return l10n?.fertilizeEvery ?? 'Feed every';
      case CareType.mist:
        return l10n?.mistEvery ?? 'Mist every';
      case CareType.repot:
        return l10n?.repotEvery ?? 'Repot every';
      case CareType.prune:
        return l10n?.pruneEvery ?? 'Prune every';
      case CareType.treat:
        return l10n?.treatEvery ?? 'Treat every';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final rooms = widget.plantProvider.rooms;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      bottomNavigationBar: const SafeArea(top: false, child: AdSlot()),
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(PhosphorBold.arrowLeft, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n?.addPlantScreenTitle ?? 'Add Plant'),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
        ),
        children: [
          _PhotoPicker(photoFile: _photoFile, onTap: _pickPhoto, isDark: isDark),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n?.plantNameLabel ?? 'Plant name *',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _speciesController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n?.speciesLabel ?? 'Species (optional)',
              helperText: 'For example: Monstera deliciosa',
            ),
          ),
          if (rooms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _selectedRoomId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n?.selectRoom ?? 'Select room',
              ),
              items: [
                for (final r in rooms)
                  DropdownMenuItem(value: r.id, child: Text(r.name)),
              ],
              onChanged: (v) => setState(() => _selectedRoomId = v),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n?.careSchedule ?? 'Care Schedule',
            style: AppTypography.title1.copyWith(color: ink),
          ),
          const SizedBox(height: 2),
          Text(
            'Switch on the care this plant needs. Reminders start from today.',
            style: AppTypography.footnote.copyWith(color: sub),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final t in CareType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _CareRow(
                type: t,
                label: _label(t, l10n),
                suffix: l10n?.daysSuffix ?? 'days',
                controller: _days[t]!,
                enabled: _on[t] ?? false,
                isDark: isDark,
                onToggle: (v) => setState(() => _on[t] = v),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n?.notesLabel ?? 'Notes (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(l10n?.savePlant ?? 'Save Plant'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final File? photoFile;
  final VoidCallback onTap;
  final bool isDark;

  const _PhotoPicker({
    required this.photoFile,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: photoFile == null ? 'Add a photo' : 'Change photo',
      child: Material(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          onTap: onTap,
          child: Container(
            height: 220,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(
                color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
              ),
            ),
            child: photoFile != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(photoFile!, fit: BoxFit.cover),
                      Positioned(
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorRegular.camera,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(PhosphorFill.camera, size: 30, color: accent),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n?.addPhoto ?? 'Add Photo',
                        style: AppTypography.title2.copyWith(color: accent),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Take a photo or pick one from your gallery',
                        style: AppTypography.footnote.copyWith(color: sub),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// One care type: an on/off switch and how many days between each time.
class _CareRow extends StatelessWidget {
  final CareType type;
  final String label;
  final String suffix;
  final TextEditingController controller;
  final bool enabled;
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const _CareRow({
    required this.type,
    required this.label,
    required this.suffix,
    required this.controller,
    required this.enabled,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: enabled
              ? type.color.withOpacity(0.5)
              : (isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: type.color.withOpacity(enabled ? 0.16 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(careIcon(type), size: 19, color: type.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: enabled ? ink : sub),
            ),
          ),
          if (enabled) ...[
            SizedBox(
              width: 52,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTypography.body.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
            Text(suffix, style: AppTypography.footnote.copyWith(color: sub)),
            const SizedBox(width: 4),
          ],
          Switch(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}

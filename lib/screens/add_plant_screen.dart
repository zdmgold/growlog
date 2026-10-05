import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:growlog/l10n/app_localizations.dart';
import '../models/plant_model.dart';
import '../models/photo_entry_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';

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
  final _waterFreqController = TextEditingController(text: '7');
  final _fertilizeFreqController = TextEditingController(text: '30');
  final _mistFreqController = TextEditingController(text: '3');
  // NEW: repot/prune/treat frequency inputs, closing the gap where
  // plant_model.dart/plant_provider.dart already supported all 6 care
  // types but no UI existed to actually set these 3.
  final _repotFreqController = TextEditingController(text: '365');
  final _pruneFreqController = TextEditingController(text: '90');
  final _treatFreqController = TextEditingController(text: '14');
  String? _selectedRoomId;
  File? _photoFile;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _notesController.dispose();
    _waterFreqController.dispose();
    _fertilizeFreqController.dispose();
    _mistFreqController.dispose();
    _repotFreqController.dispose();
    _pruneFreqController.dispose();
    _treatFreqController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      _showError(l10n?.plantNameRequired ?? 'Plant name is required');
      return;
    }

    String? photoPath;
    if (_photoFile != null) {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'plant_${const Uuid().v4()}.jpg';
      photoPath = '${dir.path}/$fileName';
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
      waterFrequencyDays: int.tryParse(_waterFreqController.text) ?? 7,
      fertilizeFrequencyDays:
          int.tryParse(_fertilizeFreqController.text) ?? 30,
      mistFrequencyDays: int.tryParse(_mistFreqController.text) ?? 3,
      repotFrequencyDays: int.tryParse(_repotFreqController.text) ?? 365,
      pruneFrequencyDays: int.tryParse(_pruneFreqController.text) ?? 90,
      treatFrequencyDays: int.tryParse(_treatFreqController.text) ?? 14,
      createdAt: now,
    );

    await widget.plantProvider.addPlant(plant);
    // SURGICAL ADDITION (Fix Phase B, feature #8, item flagged for this
    // exact file): haptic confirmation on successful save — previously
    // silent.
    HapticFeedback.mediumImpact();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rooms = widget.plantProvider.rooms;
    final l10n = AppLocalizations.of(context);

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
          l10n?.addPlantScreenTitle ?? 'Add Plant',
          style: AppTypography.title1.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _PhotoPicker(
            photoFile: _photoFile,
            onGallery: _pickPhoto,
            onCamera: _takePhoto,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: l10n?.plantNameLabel ?? 'Plant name *',
              filled: true,
              fillColor:
                  isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _speciesController,
            decoration: InputDecoration(
              hintText: l10n?.speciesLabel ?? 'Species (optional)',
              filled: true,
              fillColor:
                  isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (rooms.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text(l10n?.selectRoom ?? 'Select room'),
                  value: _selectedRoomId,
                  items: rooms.map((room) {
                    return DropdownMenuItem(
                      value: room.id,
                      child: Text(room.name),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedRoomId = value),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n?.careSchedule ?? 'Care Schedule',
            style: AppTypography.title2.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _FrequencyField(
            label: l10n?.waterEvery ?? 'Water every',
            controller: _waterFreqController,
            suffix: l10n?.daysSuffix ?? 'days',
            icon: Icons.water_drop,
            iconColor: AppColors.water,
          ),
          const SizedBox(height: AppSpacing.md),
          _FrequencyField(
            label: l10n?.fertilizeEvery ?? 'Fertilize every',
            controller: _fertilizeFreqController,
            suffix: l10n?.daysSuffix ?? 'days',
            icon: Icons.science,
            iconColor: AppColors.fertilize,
          ),
          const SizedBox(height: AppSpacing.md),
          _FrequencyField(
            label: l10n?.mistEvery ?? 'Mist every',
            controller: _mistFreqController,
            suffix: l10n?.daysSuffix ?? 'days',
            icon: Icons.water,
            iconColor: AppColors.mist,
          ),
          const SizedBox(height: AppSpacing.md),
          _FrequencyField(
            label: l10n?.repotEvery ?? 'Repot every',
            controller: _repotFreqController,
            suffix: l10n?.daysSuffix ?? 'days',
            icon: Icons.yard,
            iconColor: AppColors.repot,
          ),
          const SizedBox(height: AppSpacing.md),
          _FrequencyField(
            label: l10n?.pruneEvery ?? 'Prune every',
            controller: _pruneFreqController,
            suffix: l10n?.daysSuffix ?? 'days',
            icon: Icons.content_cut,
            iconColor: AppColors.prune,
          ),
          const SizedBox(height: AppSpacing.md),
          _FrequencyField(
            label: l10n?.treatEvery ?? 'Treat every',
            controller: _treatFreqController,
            suffix: l10n?.daysSuffix ?? 'days',
            icon: Icons.healing,
            iconColor: AppColors.treat,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n?.notesLabel ?? 'Notes (optional)',
              filled: true,
              fillColor:
                  isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              child: Text(
                l10n?.savePlant ?? 'Save Plant',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// NEW (was cut off mid-declaration in the original transcript — only
/// `class _PhotoPicker extends StatelessWidget { final File? photoFile;
/// final` existed, nothing further). Reconstructed to match the app's
/// existing visual language (bgTertiary containers, AppRadii.md,
/// accent-colored affordances) and the three callbacks the caller
/// above already wires up: photoFile, onGallery, onCamera.
class _PhotoPicker extends StatelessWidget {
  final File? photoFile;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _PhotoPicker({
    required this.photoFile,
    required this.onGallery,
    required this.onCamera,
  });

  void _showPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(l10n?.takePhoto ?? 'Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  onCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n?.chooseFromGallery ?? 'Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  onGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 200,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
            width: 0.5,
          ),
        ),
        child: photoFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(photoFile!, fit: BoxFit.cover),
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n?.addPhoto ?? 'Add Photo',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
      ),
    );
  }
}

/// NEW (referenced by name in the cut-off original but its class
/// definition was never reached). A labeled numeric input row matching
/// the app's design tokens, used for water/fertilize/mist frequency.
class _FrequencyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final IconData icon;
  final Color iconColor;

  const _FrequencyField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            suffix,
            style: AppTypography.footnote.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

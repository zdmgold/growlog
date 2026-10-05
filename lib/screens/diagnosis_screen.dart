import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../services/ai/ai_client.dart';
import '../services/paul_ai_service.dart';
import '../utils/constants.dart';
import 'camera_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  final Plant plant;
  final String? initialImagePath;

  const DiagnosisScreen({
    super.key,
    required this.plantProvider,
    required this.plant,
    this.initialImagePath,
  });

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  File? _imageFile;
  bool _analyzing = false;
  DiagnosisResult? _result;

  @override
  void initState() {
    super.initState();
    final path = widget.initialImagePath;
    if (path != null) _imageFile = File(path);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1400);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _result = null;
      });
    }
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push<CameraResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CameraScreen(),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _imageFile = File(result.path);
      _result = null;
    });
  }

  Future<void> _analyze() async {
    if (_imageFile == null) return;
    HapticFeedback.mediumImpact();

    setState(() => _analyzing = true);
    final bytes = await _imageFile!.readAsBytes();

    try {
      final service = PaulAIService();
      final result = await service.diagnosePlant(bytes);
      setState(() {
        _result = result;
        _analyzing = false;
      });
    } catch (e) {
      setState(() => _analyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AiException
                  ? e.message
                  : 'Diagnosis failed. Please try again.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
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
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _openCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
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
          'Plant Health Check',
          style: AppTypography.title1.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _ImagePickerCard(
            imageFile: _imageFile,
            isDark: isDark,
            onTap: _showPicker,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_imageFile != null && !_analyzing && _result == null)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.health_and_safety),
                label: const Text(
                  'Analyze with Paul',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_analyzing) ...[
            const SizedBox(height: AppSpacing.xl),
            _ShimmerAnalysisCard(isDark: isDark),
          ],
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ResultCard(result: _result!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final File? imageFile;
  final bool isDark;
  final VoidCallback onTap;

  const _ImagePickerCard({
    required this.imageFile,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 240,
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
        child: imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile!, fit: BoxFit.cover),
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: AppColors.textTertiary.withOpacity(0.6),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap to add a plant photo',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Paul will analyze leaves, spots, and pests',
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.textTertiary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ShimmerAnalysisCard extends StatefulWidget {
  final bool isDark;
  const _ShimmerAnalysisCard({required this.isDark});

  @override
  State<_ShimmerAnalysisCard> createState() => _ShimmerAnalysisCardState();
}

class _ShimmerAnalysisCardState extends State<_ShimmerAnalysisCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final opacity = 0.3 + (_ctrl.value * 0.4);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.bgSecondaryDark
                : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 140,
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary.withOpacity(opacity * 0.5),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary.withOpacity(opacity * 0.3),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(opacity * 0.3),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: double.infinity * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(opacity * 0.3),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final DiagnosisResult result;
  final bool isDark;

  const _ResultCard({required this.result, required this.isDark});

  Color get _severityColor {
    switch (result.severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFEA580C);
      case 'medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF059669);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: _severityColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  result.severity.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: _severityColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.health_and_safety, color: _severityColor, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            result.condition,
            style: AppTypography.headline.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.description,
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(icon: Icons.healing, title: 'Treatment', color: AppColors.accent),
          const SizedBox(height: AppSpacing.sm),
          ...result.treatmentSteps.asMap().entries.map((e) {
            return _StepRow(
              number: e.key + 1,
              text: e.value,
              isDark: isDark,
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(icon: Icons.shield_outlined, title: 'Prevention', color: AppColors.accent),
          const SizedBox(height: AppSpacing.sm),
          ...result.preventionTips.asMap().entries.map((e) {
            return _StepRow(
              number: e.key + 1,
              text: e.value,
              isDark: isDark,
            );
          }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.title2.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;
  final bool isDark;

  const _StepRow({
    required this.number,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(              text,
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/photo_entry_model.dart';
import '../models/plant_model.dart';
import '../models/scan_record.dart';
import '../providers/plant_provider.dart';
import '../services/ai/ai_client.dart';
import '../services/interstitial_service.dart';
import '../services/scan_service.dart';
import '../services/scan_store.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';
import '../utils/image_prep.dart';
import '../utils/phosphor_icons.dart';
import '../widgets/ad_slot.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/scan_widgets.dart';
import 'ai_setup_screen.dart';
import 'paul_chat_screen.dart';
import 'plant_detail_screen.dart';

enum _Phase { analyzing, done, error }

/// Scan result: runs a new analysis for [imagePath], or shows a saved [record].
/// With a [plant], it works as the plant's Doctor and keeps the result in that
/// plant's history instead of offering "Save to garden".
class ScanScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  final String? imagePath;
  final ScanRecord? record;
  final Plant? plant;

  const ScanScreen({
    super.key,
    required this.plantProvider,
    this.imagePath,
    this.record,
    this.plant,
  }) : assert(imagePath != null || record != null);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.analyzing;
  ScanRecord? _record;
  String? _error;
  bool _authError = false;
  bool _saving = false;
  bool _taskCounted = false;
  bool _unfurl = false;
  bool _leaving = false;
  late final AnimationController _sweep;

  /// A scan done just now (not one opened from history) that holds a plant.
  bool get _freshResult =>
      _phase == _Phase.done &&
      widget.record == null &&
      (_record?.isPlant ?? false);

  /// One finished scan counts as one task, however many ad points it passes.
  Future<void> _interstitial() async {
    final count = !_taskCounted;
    _taskCounted = true;
    await InterstitialService.afterTask(count: count);
  }

  /// Interstitial point 2: leaving a fresh result.
  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    if (_freshResult) await _interstitial();
    if (mounted) Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    if (widget.record != null) {
      _record = widget.record;
      _phase = _Phase.done;
    } else {
      _run();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _phase = _Phase.analyzing;
      _error = null;
      _authError = false;
    });
    try {
      final bytes = await compute(prepareImageForAi, widget.imagePath!);
      final id = const Uuid().v4();
      final dir = await getApplicationDocumentsDirectory();
      final stored = '${dir.path}/scan_$id.jpg';
      await File(stored).writeAsBytes(bytes);

      final rec = await ScanService.analyze(
        bytes,
        id: id,
        imagePath: stored,
        plantId: widget.plant?.id,
      );
      if (rec.isPlant) {
        await ScanStore.instance.add(rec);
        final plant = widget.plant;
        if (plant != null) {
          final photoPath = '${dir.path}/plant_${const Uuid().v4()}.jpg';
          await File(stored).copy(photoPath);
          await widget.plantProvider.addPhoto(
            plant.id,
            PhotoEntry(
              id: const Uuid().v4(),
              plantId: plant.id,
              date: DateTime.now(),
              path: photoPath,
              notes: rec.hasIssue ? 'Health check: ${rec.issue}' : 'Health check: healthy',
            ),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _record = rec;
        _phase = _Phase.done;
      });
      HapticFeedback.mediumImpact();
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = e.message;
        _authError = e.isAuth;
      });
    } catch (e) {
      debugPrint('ScanScreen._run error: $e');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = 'Something went wrong while scanning. Please try again.';
      });
    }
  }

  Future<void> _saveToGarden() async {
    final r = _record;
    if (r == null || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photoPath = '${dir.path}/plant_${const Uuid().v4()}.jpg';
      await File(r.imagePath).copy(photoPath);
      final plantId = const Uuid().v4();
      final now = DateTime.now();
      final plant = Plant(
        id: plantId,
        name: r.commonName,
        species: r.latinName,
        acquiredDate: now,
        createdAt: now,
        photos: [
          PhotoEntry(
            id: const Uuid().v4(),
            plantId: plantId,
            date: now,
            path: photoPath,
            notes: 'First scan',
          ),
        ],
        waterFrequencyDays: r.waterDays,
        fertilizeFrequencyDays: r.fertilizeDays,
      );
      await widget.plantProvider.addPlant(plant);
      await ScanStore.instance.markSaved(r.id, plantId);
      if (!mounted) return;
      final animate = !reduceMotion(context);
      setState(() {
        _record = r.copyWith(savedPlantId: plantId);
        _saving = false;
        _unfurl = animate;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${r.commonName} added to your garden')),
      );
      // Let the leaf finish before any full-screen ad.
      if (animate) await Future.delayed(const Duration(milliseconds: 750));
      // Interstitial point 1: saving to the garden is a finished task.
      await _interstitial();
    } catch (e) {
      debugPrint('ScanScreen._saveToGarden error: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the plant. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openSavedPlant(String plantId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantDetailScreen(
          plantProvider: widget.plantProvider,
          plantId: plantId,
        ),
      ),
    );
  }

  void _askPaul() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaulChatScreen(
          plantProvider: widget.plantProvider,
          plant: widget.plant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_freshResult,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      bottomNavigationBar: _phase == _Phase.done
          ? const SafeArea(top: false, child: AdSlot())
          : null,
      body: switch (_phase) {
        _Phase.analyzing => _buildAnalyzing(isDark),
        _Phase.error => _buildError(isDark),
        _Phase.done => _buildResult(isDark),
      },
      ),
    );
  }

  Widget _photo() {
    final path = _record?.imagePath ?? widget.imagePath!;
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
    );
  }

  Widget _backButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Semantics(
          button: true,
          label: 'Back',
          child: Material(
            color: Colors.black.withOpacity(0.45),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _leave,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(PhosphorBold.arrowLeft, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzing(bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _photo(),
        Container(color: Colors.black.withOpacity(0.35)),
        AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            return Align(
              alignment: Alignment(0, -0.8 + 1.6 * _sweep.value),
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentLight.withOpacity(0),
                      AppColors.accentLight,
                      AppColors.accentLight.withOpacity(0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Looking closely…',
                      style: AppTypography.callout.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _backButton(),
      ],
    );
  }

  Widget _buildError(bool isDark) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorFill.warning,
                  size: 52,
                  color: isDark ? AppColors.errorDark : AppColors.attention,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'The scan did not finish',
                  style: AppTypography.title1.copyWith(color: ink),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error ?? 'Please try again.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(color: sub),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _run,
                    child: const Text('Try again'),
                  ),
                ),
                if (_authError || (_error?.contains('API key') ?? false))
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiSetupScreen()),
                    ),
                    child: const Text('Check my API key'),
                  ),
              ],
            ),
          ),
        ),
        _backButtonOnLight(isDark),
      ],
    );
  }

  Widget _backButtonOnLight(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: IconButton(
          tooltip: 'Back',
          icon: Icon(
            PhosphorBold.arrowLeft,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildResult(bool isDark) {
    final r = _record!;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final sheet = isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary;

    if (!r.isPlant) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorRegular.leaf, size: 52, color: sub),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    "That doesn't look like a plant",
                    style: AppTypography.title1.copyWith(color: ink),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Try again with a clear, close photo of a leaf or the whole plant.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(color: sub),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final saved = r.savedPlantId != null;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 320,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _photo(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.transparent,
                          sheet.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: reduceMotion(context) ? 1.0 : 0.0,
                end: 1.0,
              ),
              duration: reduceMotion(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, -28 + (1 - t) * 90),
                  child: child,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120,
                ),
                decoration: BoxDecoration(
                  color: sheet,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.xl),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ScanHealthPill(health: r.health),
                        _InfoChip(
                          text: '${r.confidence} confidence',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.commonName,
                                style: AppTypography.display.copyWith(color: ink),
                              ),
                              if (r.latinName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    r.latinName!,
                                    style: AppTypography.latin.copyWith(
                                      color: sub,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Builder(builder: (context) {
                          final st = scanHealthStyle(r.health, isDark, context.l10n);
                          return HealthRing(color: st.color, icon: st.icon);
                        }),
                      ],
                    ),
                    if (r.summary.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        r.summary,
                        style: AppTypography.body.copyWith(color: ink),
                      ),
                    ],
                    if (r.hasIssue) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _IssueCard(record: r, isDark: isDark),
                    ],
                    if (r.treatment.isNotEmpty && r.hasIssue) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _StepsCard(
                        title: 'What to do',
                        steps: r.treatment,
                        isDark: isDark,
                      ),
                    ],
                    if (r.waterDays != null || r.fertilizeDays != null || r.light != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _CareCard(record: r, isDark: isDark),
                    ],
                    if (r.prevention.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _StepsCard(
                        title: 'Keep it healthy',
                        steps: r.prevention,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'AI guidance can be wrong. For a serious problem, check with a local nursery.',
                      style: AppTypography.caption.copyWith(color: sub),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        _backButton(),
        if (_unfurl)
          LeafUnfurl(
            onDone: () {
              if (mounted) setState(() => _unfurl = false);
            },
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _ActionBar(
            isDark: isDark,
            saving: _saving,
            doctorPlant: widget.plant,
            saved: saved,
            onSave: _saveToGarden,
            onOpenPlant: saved ? () => _openSavedPlant(r.savedPlantId!) : null,
            onDone: _leave,
            onPaul: _askPaul,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final bool isDark;
  const _InfoChip({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final ScanRecord record;
  final bool isDark;
  const _IssueCard({required this.record, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final st = scanHealthStyle(record.health, isDark, context.l10n);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: st.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: st.color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(st.icon, color: st.color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.issue,
                  style: AppTypography.title2.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Severity: ${record.severity}',
                  style: AppTypography.footnote.copyWith(color: st.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final String title;
  final List<String> steps;
  final bool isDark;
  const _StepsCard({
    required this.title,
    required this.steps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
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
          Text(title, style: AppTypography.title1.copyWith(color: ink, fontSize: 19)),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTypography.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppTypography.callout.copyWith(color: ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  final ScanRecord record;
  final bool isDark;
  const _CareCard({required this.record, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    Widget row(IconData icon, Color color, String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTypography.callout.copyWith(color: sub)),
            ),
            Text(value, style: AppTypography.callout.copyWith(color: ink)),
          ],
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
          Text('Suggested care',
              style: AppTypography.title1.copyWith(color: ink, fontSize: 19)),
          const SizedBox(height: 2),
          Text(
            'Starting points from the AI. Adjust them once you know your plant.',
            style: AppTypography.caption.copyWith(color: sub),
          ),
          const SizedBox(height: AppSpacing.md),
          if (record.waterDays != null)
            row(PhosphorFill.drop, AppColors.water, 'Water',
                'every ${record.waterDays} days'),
          if (record.fertilizeDays != null)
            row(PhosphorFill.flask, AppColors.fertilize, 'Feed',
                'every ${record.fertilizeDays} days'),
          if (record.light != null)
            row(PhosphorFill.sun, AppColors.watch, 'Light', record.light!),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isDark;
  final bool saving;
  final bool saved;
  final Plant? doctorPlant;
  final VoidCallback onSave;
  final VoidCallback? onOpenPlant;
  final VoidCallback onDone;
  final VoidCallback onPaul;

  const _ActionBar({
    required this.isDark,
    required this.saving,
    required this.saved,
    required this.doctorPlant,
    required this.onSave,
    required this.onOpenPlant,
    required this.onDone,
    required this.onPaul,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;

    Widget primary;
    if (doctorPlant != null) {
      primary = ElevatedButton(
        onPressed: onDone,
        child: Text('Saved to ${doctorPlant!.name}'),
      );
    } else if (saved) {
      primary = ElevatedButton.icon(
        onPressed: onOpenPlant,
        icon: const Icon(PhosphorFill.checkCircle, size: 20),
        label: const Text('In your garden · Open'),
      );
    } else {
      primary = ElevatedButton.icon(
        onPressed: saving ? null : onSave,
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(PhosphorBold.plus, size: 20),
        label: Text(saving ? 'Saving…' : 'Save to garden'),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: SizedBox(height: 52, child: primary)),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            button: true,
            label: 'Ask Paul',
            child: Material(
              color: accent.withOpacity(0.14),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPaul,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(PhosphorRegular.chatCircleDots, color: accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

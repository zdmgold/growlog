import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/l10n_ext.dart';
import '../models/photo_entry_model.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../services/ai/ai_settings.dart';
import '../services/interstitial_service.dart';
import '../services/offline/identify_math.dart';
import '../services/offline/offline_model_service.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import '../widgets/ad_slot.dart';
import 'scan_screen.dart';

enum _Phase { analyzing, done, error }

/// Identifies a plant photo on this phone with the offline model. Shows the best
/// guesses to pick from, and offers to save the plant or ask an AI for a second
/// opinion when a key is connected.
class OfflineIdentifyScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  final String imagePath;

  const OfflineIdentifyScreen({
    super.key,
    required this.plantProvider,
    required this.imagePath,
  });

  @override
  State<OfflineIdentifyScreen> createState() => _OfflineIdentifyScreenState();
}

class _OfflineIdentifyScreenState extends State<OfflineIdentifyScreen> {
  _Phase _phase = _Phase.analyzing;
  IdentifyResult? _result;
  String? _selected;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _phase = _Phase.analyzing;
      _error = null;
    });
    try {
      final r = await OfflineModelService.instance.identify(widget.imagePath);
      if (!mounted) return;
      setState(() {
        _result = r;
        _selected = r.confident && r.guesses.isNotEmpty
            ? r.guesses.first.species
            : null;
        _phase = _Phase.done;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('OfflineIdentifyScreen._run error: $e');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = 'Could not identify this photo on the phone. Try again with a clearer photo.';
      });
    }
  }

  Future<void> _save() async {
    final name = _selected;
    if (name == null || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photoPath = '${dir.path}/plant_${const Uuid().v4()}.jpg';
      await File(widget.imagePath).copy(photoPath);
      final plantId = const Uuid().v4();
      final now = DateTime.now();
      await widget.plantProvider.addPlant(
        Plant(
          id: plantId,
          name: name,
          species: name,
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
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addedToGarden(name))),
      );
      // Interstitial point 1: saving to the garden is a finished task.
      await InterstitialService.afterTask(count: true);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('OfflineIdentifyScreen._save error: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.couldNotSavePlant),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _secondOpinion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          plantProvider: widget.plantProvider,
          imagePath: widget.imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final hasKey = AiSettings.instance.isConfigured;

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const SafeArea(top: false, child: AdSlot()),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(PhosphorRegular.arrowLeft, color: ink),
                  ),
                  Text('Identify', style: AppTypography.title1.copyWith(color: ink)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: SizedBox(
                      height: 220,
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark
                              ? AppColors.bgTertiaryDark
                              : AppColors.bgTertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_phase == _Phase.analyzing) ..._analyzing(ink, sub),
                  if (_phase == _Phase.error) ..._errorView(ink, sub, hasKey),
                  if (_phase == _Phase.done) ..._resultView(ink, sub, isDark, hasKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _analyzing(Color ink, Color sub) => [
        const SizedBox(height: AppSpacing.lg),
        const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text('Identifying on this phone…',
              style: AppTypography.headline.copyWith(color: ink)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text('No internet needed. This can take a few seconds.',
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: sub)),
        ),
      ];

  List<Widget> _errorView(Color ink, Color sub, bool hasKey) => [
        Text('Something went wrong',
            style: AppTypography.title1.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.xs),
        Text(_error ?? '', style: AppTypography.callout.copyWith(color: sub)),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: _run, child: const Text('Try again')),
        if (hasKey) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
              onPressed: _secondOpinion, child: const Text('Ask the AI instead')),
        ],
      ];

  List<Widget> _resultView(Color ink, Color sub, bool isDark, bool hasKey) {
    final r = _result!;
    if (!r.accepted || r.guesses.isEmpty) {
      return [
        Text("I'm not sure what this is",
            style: AppTypography.title1.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "It doesn't look like a plant I know yet. Try a closer photo of a leaf or the whole plant in good light.",
          style: AppTypography.callout.copyWith(color: sub),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Take another photo')),
        if (hasKey) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
              onPressed: _secondOpinion,
              child: const Text('Second opinion with AI')),
        ],
      ];
    }
    final top = r.guesses.take(3).toList();
    return [
      Text(
        r.confident ? 'Looks like this' : 'Which one is it?',
        style: AppTypography.title1.copyWith(color: ink),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        r.confident
            ? 'Identified on this phone. Pick another if it is not right.'
            : 'These are the closest matches. Tap the right one.',
        style: AppTypography.callout.copyWith(color: sub),
      ),
      const SizedBox(height: AppSpacing.md),
      for (var i = 0; i < top.length; i++) ...[
        _GuessTile(
          guess: top[i],
          selected: _selected == top[i].species,
          likely: i == 0 && r.confident,
          onTap: () => setState(() => _selected = top[i].species),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      const SizedBox(height: AppSpacing.xs),
      Text(
        "Health isn't checked offline. After saving, use Doctor on the plant with an AI key for a health check.",
        style: AppTypography.footnote.copyWith(color: sub),
      ),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: (_selected == null || _saving) ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save to garden'),
      ),
      if (hasKey) ...[
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
            onPressed: _secondOpinion,
            child: const Text('Second opinion with AI')),
      ],
    ];
  }
}

class _GuessTile extends StatelessWidget {
  final SpeciesGuess guess;
  final bool selected;
  final bool likely;
  final VoidCallback onTap;

  const _GuessTile({
    required this.guess,
    required this.selected,
    required this.likely,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final pct = (guess.probability * 100).clamp(0, 100).toStringAsFixed(0);
    return Material(
      color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : (isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? PhosphorRegular.checkCircle : PhosphorRegular.leaf,
                color: selected ? AppColors.accent : sub,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  guess.species,
                  style: TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 18,
                    color: ink,
                  ),
                ),
              ),
              Text(
                likely ? 'Likely · $pct%' : '$pct%',
                style: AppTypography.caption.copyWith(color: sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

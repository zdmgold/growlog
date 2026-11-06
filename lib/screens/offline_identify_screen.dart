import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/l10n_ext.dart';
import '../models/photo_entry_model.dart';
import '../models/plant_model.dart';
import '../models/scan_record.dart';
import '../providers/plant_provider.dart';
import '../services/ai/ai_settings.dart';
import '../services/interstitial_service.dart';
import '../services/offline/care_guide.dart';
import '../services/offline/identify_math.dart';
import '../services/offline/offline_model_service.dart';
import '../services/scan_store.dart';
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

  /// Set when reopening a saved offline scan from the Scans history. The
  /// stored guesses are shown, so the model does not run again.
  final ScanRecord? record;

  const OfflineIdentifyScreen({
    super.key,
    required this.plantProvider,
    required this.imagePath,
    this.record,
  });

  @override
  State<OfflineIdentifyScreen> createState() => _OfflineIdentifyScreenState();
}

class _OfflineIdentifyScreenState extends State<OfflineIdentifyScreen> {
  _Phase _phase = _Phase.analyzing;
  IdentifyResult? _result;
  String? _selected;
  bool _saving = false;
  bool _failed = false;
  String? _recordId;

  @override
  void initState() {
    super.initState();
    final rec = widget.record;
    if (rec != null) {
      _openSaved(rec);
    } else {
      _run();
    }
  }

  /// Rebuilds the result from a saved scan.
  Future<void> _openSaved(ScanRecord rec) async {
    await CareGuide.instance.load();
    final guesses = <SpeciesGuess>[];
    for (final line in rec.candidates) {
      final p = line.split('|');
      if (p.length < 3) continue;
      guesses.add(SpeciesGuess(
          p[0], double.tryParse(p[1]) ?? 0, double.tryParse(p[2]) ?? 0));
    }
    if (!mounted) return;
    setState(() {
      _recordId = rec.id;
      _result = IdentifyResult(
        guesses: guesses,
        accepted: guesses.isNotEmpty,
        confident: rec.confidence == 'High',
      );
      _selected = rec.confidence == 'High' && guesses.isNotEmpty
          ? guesses.first.species
          : null;
      _phase = _Phase.done;
    });
  }

  /// Keeps an accepted result in the Scans history, with its own copy of the
  /// photo so it survives the camera's temporary file being cleared.
  Future<void> _remember(IdentifyResult r) async {
    if (!r.accepted || r.guesses.isEmpty) return;
    try {
      final id = const Uuid().v4();
      final dir = await getApplicationDocumentsDirectory();
      final stored = '${dir.path}/scan_$id.jpg';
      await File(widget.imagePath).copy(stored);
      final top = r.guesses.first;
      final care = CareGuide.instance.lookup(top.species);
      await ScanStore.instance.add(ScanRecord(
        id: id,
        imagePath: stored,
        createdAt: DateTime.now(),
        commonName: care?.common ?? top.species,
        latinName: top.species,
        confidence: r.confident ? 'High' : 'Medium',
        source: 'device',
        candidates: [
          for (final g in r.guesses.take(3))
            '${g.species}|${g.probability}|${g.cosine}',
        ],
      ));
      _recordId = id;
    } catch (e) {
      debugPrint('OfflineIdentifyScreen._remember error: $e');
    }
  }

  Future<void> _run() async {
    await CareGuide.instance.load();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.analyzing;
      _failed = false;
    });
    try {
      final r = await OfflineModelService.instance.identify(widget.imagePath);
      if (!mounted) return;
      await _remember(r);
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
        _failed = true;
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
      final care = CareGuide.instance.lookup(name);
      final displayName = care?.common ?? name;
      await widget.plantProvider.addPlant(
        Plant(
          id: plantId,
          name: displayName,
          species: name,
          acquiredDate: now,
          createdAt: now,
          waterFrequencyDays: care?.waterDays,
          fertilizeFrequencyDays: care?.feedDays,
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
      final rid = _recordId;
      if (rid != null) await ScanStore.instance.markSaved(rid, plantId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addedToGarden(displayName))),
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
                  Text(context.l10n.offIdentify, style: AppTypography.title1.copyWith(color: ink)),
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
          child: Text(context.l10n.offIdentifying,
              style: AppTypography.headline.copyWith(color: ink)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(context.l10n.offNoInternetNeeded,
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: sub)),
        ),
      ];

  List<Widget> _errorView(Color ink, Color sub, bool hasKey) => [
        Text(context.l10n.offWentWrong,
            style: AppTypography.title1.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.xs),
        Text(context.l10n.offIdentifyError,
            style: AppTypography.callout.copyWith(color: sub)),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: _run, child: Text(context.l10n.tryAgain)),
        if (hasKey) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
              onPressed: _secondOpinion, child: Text(context.l10n.offAskAiInstead)),
        ],
      ];

  List<Widget> _resultView(Color ink, Color sub, bool isDark, bool hasKey) {
    final r = _result!;
    if (!r.accepted || r.guesses.isEmpty) {
      return [
        Text(context.l10n.offNotSure,
            style: AppTypography.title1.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.offNotSureHint,
          style: AppTypography.callout.copyWith(color: sub),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.offTakeAnother)),
        if (hasKey) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
              onPressed: _secondOpinion,
              child: Text(context.l10n.offSecondOpinion)),
        ],
      ];
    }
    final top = r.guesses.take(3).toList();
    return [
      Text(
        r.confident ? context.l10n.offLooksLikeThis : context.l10n.offWhichOne,
        style: AppTypography.title1.copyWith(color: ink),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        r.confident
            ? context.l10n.offConfidentSub
            : context.l10n.offPickSub,
        style: AppTypography.callout.copyWith(color: sub),
      ),
      const SizedBox(height: AppSpacing.md),
      for (var i = 0; i < top.length; i++) ...[
        _GuessTile(
          guess: top[i],
          care: CareGuide.instance.lookup(top[i].species),
          selected: _selected == top[i].species,
          likely: i == 0 && r.confident,
          onTap: () => setState(() => _selected = top[i].species),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (_selected != null && CareGuide.instance.lookup(_selected!) != null)
        _CareCard(entry: CareGuide.instance.lookup(_selected!)!),
      const SizedBox(height: AppSpacing.xs),
      Text(
        context.l10n.offHealthNote,
        style: AppTypography.footnote.copyWith(color: sub),
      ),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: (_selected == null || _saving) ? null : _save,
        child: Text(_saving ? context.l10n.saving : context.l10n.saveToGarden),
      ),
      if (hasKey) ...[
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
            onPressed: _secondOpinion,
            child: Text(context.l10n.offSecondOpinion)),
      ],
    ];
  }
}

class _GuessTile extends StatelessWidget {
  final SpeciesGuess guess;
  final CareEntry? care;
  final bool selected;
  final bool likely;
  final VoidCallback onTap;

  const _GuessTile({
    required this.guess,
    required this.care,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (care != null)
                      Text(
                        care!.common,
                        style: TextStyle(
                          fontFamily: AppTypography.serif,
                          fontSize: 18,
                          color: ink,
                        ),
                      ),
                    Text(
                      guess.species,
                      style: TextStyle(
                        fontFamily: AppTypography.serif,
                        fontStyle: FontStyle.italic,
                        fontSize: care != null ? 14 : 18,
                        color: care != null ? sub : ink,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                likely ? context.l10n.offLikely(pct) : '$pct%',
                style: AppTypography.caption.copyWith(color: sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  final CareEntry entry;
  const _CareCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final l = context.l10n;
    String light() {
      switch (entry.light) {
        case CareLight.brightIndirect:
          return l.offLightBrightIndirect;
        case CareLight.medium:
          return l.offLightMedium;
        case CareLight.low:
          return l.offLightLow;
        case CareLight.direct:
          return l.offLightDirect;
      }
    }

    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(text,
                    style: AppTypography.callout.copyWith(color: ink)),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.offCareTitle, style: AppTypography.headline.copyWith(color: ink)),
          row(PhosphorRegular.drop, l.offCareWater('${entry.waterDays}')),
          if (entry.feedDays != null)
            row(PhosphorRegular.flask, l.offCareFeed('${entry.feedDays}')),
          row(PhosphorRegular.sun, light()),
          const SizedBox(height: 8),
          Text(l.offCareNote, style: AppTypography.footnote.copyWith(color: sub)),
        ],
      ),
    );
  }
}

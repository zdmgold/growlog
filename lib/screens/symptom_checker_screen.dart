import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/l10n_ext.dart';
import '../services/offline/symptom_checker.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// Guided offline check: where, what, pattern, context, then ranked causes.
class SymptomCheckerScreen extends StatefulWidget {
  /// Shown in the header when the check was started from a plant's page.
  final String? plantName;
  const SymptomCheckerScreen({super.key, this.plantName});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  static const _steps = ['part', 'symptom', 'pattern', 'context'];

  SymptomChecker? _checker;
  bool _failed = false;
  int _step = 0;
  bool _showResults = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    SymptomChecker.load().then((c) {
      if (mounted) setState(() => _checker = c);
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  String _title(int step) {
    final l = context.l10n;
    switch (_steps[step]) {
      case 'part':
        return l.symptomStepWhere;
      case 'symptom':
        return l.symptomStepWhat;
      case 'pattern':
        return l.symptomStepPattern;
      default:
        return l.symptomStepContext;
    }
  }

  bool get _canAdvance {
    if (_steps[_step] != 'symptom') return true;
    final c = _checker;
    if (c == null) return false;
    return c.groups['symptom']!.any((o) => _selected.contains(o.id));
  }

  void _next() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_step < _steps.length - 1) {
        _step++;
      } else {
        _showResults = true;
      }
    });
  }

  void _back() {
    if (_showResults) {
      setState(() => _showResults = false);
    } else if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  void _restart() => setState(() {
        _selected.clear();
        _step = 0;
        _showResults = false;
      });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final l10n = context.l10n;

    return PopScope(
      canPop: !_showResults && _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: l10n.backLabel,
            icon: Icon(PhosphorBold.arrowLeft, color: ink),
            onPressed: _back,
          ),
          title: Text(widget.plantName == null
              ? l10n.symptomCheckerTitle
              : l10n.symptomForPlant(widget.plantName!)),
        ),
        body: SafeArea(
          child: _failed
              ? Center(child: Text(l10n.errorMessage))
              : _checker == null
                  ? const Center(child: CircularProgressIndicator())
                  : (_showResults ? _results(isDark) : _stepView(isDark)),
        ),
      ),
    );
  }

  Widget _stepView(bool isDark) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final l10n = context.l10n;
    final options = _checker!.groups[_steps[_step]]!;
    final last = _step == _steps.length - 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            children: [
              if (_step == 0) ...[
                Text(l10n.symptomCheckerIntro,
                    style: AppTypography.body.copyWith(color: sub)),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('${_step + 1} / ${_steps.length}',
                  style: AppTypography.caption.copyWith(color: sub)),
              const SizedBox(height: AppSpacing.xs),
              Text(_title(_step),
                  style: AppTypography.title1.copyWith(color: ink)),
              const SizedBox(height: 2),
              Text(l10n.symptomPickHint,
                  style: AppTypography.footnote.copyWith(color: sub)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final o in options)
                    _OptionChip(
                      label: o.label,
                      selected: _selected.contains(o.id),
                      isDark: isDark,
                      onTap: () => setState(() {
                        HapticFeedback.selectionClick();
                        if (!_selected.remove(o.id)) _selected.add(o.id);
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canAdvance ? _next : null,
              child: Text(last ? l10n.symptomSeeResults : l10n.symptomNext),
            ),
          ),
        ),
      ],
    );
  }

  Widget _results(bool isDark) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final l10n = context.l10n;
    final found = _checker!.rank(_selected);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
      children: [
        Text(l10n.symptomResultsTitle,
            style: AppTypography.title1.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.md),
        if (found.isEmpty)
          Text(l10n.symptomNothingFound,
              style: AppTypography.body.copyWith(color: sub))
        else
          for (var i = 0; i < found.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ResultCard(
                  diagnosis: found[i], isDark: isDark, initiallyOpen: i == 0),
            ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.symptomDisclaimer,
            style: AppTypography.footnote.copyWith(color: sub)),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _restart,
            child: Text(l10n.symptomStartOver),
          ),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : (isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary),
          shape: StadiumBorder(
            side: BorderSide(
              color: selected
                  ? accent
                  : (isDark
                      ? AppColors.borderSubtleDark
                      : AppColors.borderSubtle),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      Icon(PhosphorBold.check, size: 16, color: accent),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(label,
                          style: AppTypography.callout.copyWith(color: ink)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Diagnosis diagnosis;
  final bool isDark;
  final bool initiallyOpen;
  const _ResultCard({
    required this.diagnosis,
    required this.isDark,
    required this.initiallyOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = diagnosis.problem;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final String conf;
    switch (diagnosis.confidence) {
      case Confidence.mostLikely:
        conf = l10n.symptomMostLikely;
      case Confidence.possible:
        conf = l10n.symptomPossible;
      case Confidence.lessLikely:
        conf = l10n.symptomLessLikely;
    }
    final Color tone;
    final IconData icon;
    switch (p.severity) {
      case 'high':
        tone = AppColors.attention;
        icon = PhosphorFill.warningCircle;
      case 'med':
        tone = isDark ? AppColors.warningDark : AppColors.watchText;
        icon = PhosphorFill.warning;
      default:
        tone = isDark ? AppColors.successDark : AppColors.success;
        icon = PhosphorFill.checkCircle;
    }

    Widget section(String title, Widget body) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.caption.copyWith(color: sub)),
              const SizedBox(height: 4),
              body,
            ],
          ),
        );
    final bodyStyle = AppTypography.body.copyWith(color: ink);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyOpen,
          tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Icon(icon, color: tone),
          title: Text(p.name,
              style: AppTypography.headline.copyWith(color: ink)),
          subtitle: Text(conf,
              style: AppTypography.footnote.copyWith(color: tone)),
          children: [
            Text(p.what, style: bodyStyle),
            section(l10n.symptomCheckFirst, Text(p.check, style: bodyStyle)),
            section(
              l10n.symptomWhatToDo,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < p.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${i + 1}. ${p.steps[i]}', style: bodyStyle),
                    ),
                ],
              ),
            ),
            section(l10n.symptomPrevention, Text(p.prevent, style: bodyStyle)),
            section(l10n.symptomWhenToWorry, Text(p.worry, style: bodyStyle)),
          ],
        ),
      ),
    );
  }
}

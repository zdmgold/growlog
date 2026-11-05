import 'package:flutter/material.dart';
import '../l10n/l10n_ext.dart';
import '../screens/symptom_checker_screen.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// Entry to the offline symptom check. Works with no key and no internet.
class SymptomEntryCard extends StatelessWidget {
  final String? plantName;
  const SymptomEntryCard({super.key, this.plantName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final l10n = context.l10n;

    return Material(
      color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SymptomCheckerScreen(plantName: plantName),
          ),
        ),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorFill.stethoscope, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.symptomCheckerTitle,
                        style: AppTypography.headline.copyWith(color: ink)),
                    const SizedBox(height: 2),
                    Text(l10n.symptomCheckerIntro,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.footnote.copyWith(color: sub)),
                  ],
                ),
              ),
              Icon(PhosphorBold.caretRight, size: 18, color: sub),
            ],
          ),
        ),
      ),
    );
  }
}

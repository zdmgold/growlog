import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:growlog/l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// Wordmark, language / theme / settings icons, greeting and status line.
class HomeHeader extends StatelessWidget {
  final ThemeProvider themeProvider;
  final int dueCount;
  final int plantCount;
  final VoidCallback onLanguage;
  final VoidCallback onSettings;

  const HomeHeader({
    super.key,
    required this.themeProvider,
    required this.dueCount,
    required this.plantCount,
    required this.onLanguage,
    required this.onSettings,
  });

  String _greeting(AppLocalizations l) {
    final h = DateTime.now().hour;
    if (h < 12) return l.greetingMorning;
    if (h < 17) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  String _status(AppLocalizations l) {
    if (plantCount == 0) return l.statusEmptyGarden;
    if (dueCount == 0) return l.statusUpToDate;
    return l.statusDue(dueCount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = context.l10n;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(PhosphorFill.leaf, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'GrowLog',
                style: AppTypography.title1.copyWith(color: ink),
              ),
              const Spacer(),
              _HeaderIcon(
                icon: PhosphorRegular.translate,
                label: l.headerChangeLanguage,
                isDark: isDark,
                onTap: onLanguage,
              ),
              const SizedBox(width: AppSpacing.sm),
              _HeaderIcon(
                icon: isDark ? PhosphorRegular.sun : PhosphorRegular.moon,
                label: isDark ? l.headerToLight : l.headerToDark,
                isDark: isDark,
                onTap: () => themeProvider.setTheme(
                  isDark ? ThemeMode.light : ThemeMode.dark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _HeaderIcon(
                icon: PhosphorRegular.gearSix,
                label: l.settingsTitle,
                isDark: isDark,
                onTap: onSettings,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(_greeting(l), style: AppTypography.headline.copyWith(color: ink)),
          const SizedBox(height: 4),
          Text(_status(l), style: AppTypography.body.copyWith(color: sub)),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        shape: CircleBorder(
          side: BorderSide(
            color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 21,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

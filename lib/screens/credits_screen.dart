import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';

/// Credits for the model, fonts and icons, plus Flutter's own list of every
/// open-source package licence used by the app.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final l10n = context.l10n;

    Widget section(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.title2.copyWith(color: ink)),
              const SizedBox(height: 4),
              Text(body, style: AppTypography.body.copyWith(color: sub)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(title: Text(l10n.licencesAndCredits)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          section(l10n.creditsIdentifier, l10n.creditsIdentifierBody),
          section(
            l10n.creditsDesign,
            '${l10n.creditsDesignBody}\nSeedling logo: Noto Emoji by Google (Apache 2.0).',
          ),
          section(l10n.creditsGuide, l10n.creditsGuideBody),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                final info = await PackageInfo.fromPlatform();
                if (!context.mounted) return;
                showLicensePage(
                  context: context,
                  applicationName: 'GrowLog',
                  applicationVersion: info.version,
                );
              },
              child: Text(l10n.openSourceLicences),
            ),
          ),
        ],
      ),
    );
  }
}

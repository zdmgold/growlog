import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/locale_provider.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

const List<(String, String)> _languages = [
  ('en', 'English'),
  ('es', 'Español'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
  ('pt', 'Português'),
  ('ar', 'العربية'),
  ('hi', 'हिन्दी'),
  ('ja', '日本語'),
  ('ko', '한국어'),
  ('zh', '中文'),
  ('he', 'עברית'),
];

Future<void> showLanguageSheet(
  BuildContext context,
  LocaleProvider provider,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LanguageSheet(provider: provider),
  );
}

class _LanguageSheet extends StatelessWidget {
  final LocaleProvider provider;
  const _LanguageSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final maxH = MediaQuery.of(context).size.height * 0.78;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        child: ListenableBuilder(
          listenable: provider,
          builder: (context, _) {
            final current = provider.value?.languageCode;
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg,
              ),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Language', style: AppTypography.title1.copyWith(color: ink)),
                const SizedBox(height: AppSpacing.sm),
                _row(context, ink, 'Phone default', current == null, () {
                  provider.setLocale(null);
                  Navigator.pop(context);
                }),
                for (final (code, name) in _languages)
                  _row(context, ink, name, current == code, () {
                    provider.setLocale(Locale(code));
                    Navigator.pop(context);
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    Color ink,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: ink,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              Icon(PhosphorBold.check, size: 20, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

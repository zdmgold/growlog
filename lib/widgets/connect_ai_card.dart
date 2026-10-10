import 'package:flutter/material.dart';
import '../services/ai/ai_settings.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// Home card: asks for a key until one is set, then shows a slim status pill.
class ConnectAiCard extends StatelessWidget {
  final VoidCallback onTap;
  const ConnectAiCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;

    return ListenableBuilder(
      listenable: AiSettings.instance,
      builder: (context, _) {
        final s = AiSettings.instance;
        if (s.isConfigured) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: context.l10n.aiConnectionSettings,
              child: Material(
                color: accent.withOpacity(0.12),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorFill.checkCircle, size: 16, color: accent),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.l10n.aiConnectedTo(s.provider?.name ?? ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Material(
          color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: accent.withOpacity(0.55)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(PhosphorFill.key, size: 22, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.addYourApiKey,
                          style: AppTypography.title2.copyWith(color: ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.neededForScansChat,
                          style: AppTypography.footnote.copyWith(color: sub),
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorBold.caretRight, size: 18, color: sub),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../services/ai/ai_settings.dart';
import '../services/offline/offline_model_service.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import 'identifier_gate_sheet.dart';

/// Home card: asks the person to set up plant identification (offline model or an AI
/// key) until one is ready, then shows a slim status pill.
class ConnectAiCard extends StatelessWidget {
  /// Opens the AI key settings (used by the pill when a key is connected).
  final VoidCallback onTap;
  const ConnectAiCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;

    Widget pill(String label, String semantics, VoidCallback? tap) => Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            button: tap != null,
            label: semantics,
            child: Material(
              color: accent.withOpacity(0.12),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: tap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorFill.checkCircle, size: 16, color: accent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
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

    return ListenableBuilder(
      listenable: Listenable.merge([AiSettings.instance, OfflineModelService.instance]),
      builder: (context, _) {
        final s = AiSettings.instance;
        final off = OfflineModelService.instance;
        if (s.isConfigured) {
          return pill(
            context.l10n.aiConnectedTo(s.provider?.name ?? ''),
            context.l10n.aiConnectionSettings,
            onTap,
          );
        }
        if (off.isInstalled) {
          return pill(context.l10n.offReady, context.l10n.offReady, null);
        }
        final busy = off.isBusy;
        final title = off.isDownloading
            ? context.l10n.offDownloadingCard
            : off.isWaitingForWifi
                ? context.l10n.offWaitingWifi
                : context.l10n.offSetupTitle;
        final subtitle = off.isDownloading
            ? context.l10n.offTapProgress((off.progress * 100).clamp(0, 100).toStringAsFixed(0))
            : off.isWaitingForWifi
                ? context.l10n.offWaitingWifiSub
                : context.l10n.offSetupSub;
        return Material(
          color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: () => showIdentifierGate(context),
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
                    child: busy
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: accent,
                              value: off.isDownloading && off.bytesTotal > 0
                                  ? off.progress
                                  : null,
                            ),
                          )
                        : Icon(PhosphorFill.leaf, size: 22, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.title2.copyWith(color: ink)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTypography.footnote.copyWith(color: sub)),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/ai_setup_screen.dart';
import '../services/ai/ai_settings.dart';
import '../services/offline/offline_model_service.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// Shown when a scan is started but nothing can identify plants yet: lets the person
/// download the offline model (Wi-Fi or mobile data) or connect their own AI key.
/// Returns true when identification is ready (model installed or a key connected).
Future<bool> showIdentifierGate(BuildContext context) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GateSheet(),
  );
  return ok ?? false;
}

enum _Step { choice, network }

class _GateSheet extends StatefulWidget {
  const _GateSheet();

  @override
  State<_GateSheet> createState() => _GateSheetState();
}

class _GateSheetState extends State<_GateSheet> {
  final _svc = OfflineModelService.instance;
  _Step _step = _Step.choice;
  bool _closing = false;

  void _close(bool ok) {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.pop(context, ok);
  }

  Future<void> _useKey() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiSetupScreen()),
    );
    if (mounted && AiSettings.instance.isConfigured) _close(true);
  }

  void _start(bool mobileData) {
    HapticFeedback.selectionClick();
    _svc.download(allowMobileData: mobileData);
  }

  static String _mb(int bytes) => (bytes / 1000000).toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final maxH = MediaQuery.of(context).size.height * 0.85;

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
          listenable: _svc,
          builder: (context, _) {
            if (_svc.isInstalled) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _close(true));
            }
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
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
                if (_svc.isBusy || _svc.state == OfflineModelState.failed)
                  ..._progress(ink, sub, isDark)
                else if (_step == _Step.network)
                  ..._network(ink, sub, isDark)
                else
                  ..._choice(ink, sub, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _choice(Color ink, Color sub, bool isDark) => [
        Text('Identify plants', style: AppTypography.title1.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose how GrowLog should recognise your plants.',
          style: AppTypography.callout.copyWith(color: sub),
        ),
        const SizedBox(height: AppSpacing.md),
        _OptionTile(
          icon: PhosphorRegular.downloadSimple,
          title: 'Use the offline model',
          subtitle:
              'One-time download, about 309 MB. Works without internet and keeps your photos on this phone.',
          primary: true,
          onTap: () => setState(() => _step = _Step.network),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionTile(
          icon: PhosphorRegular.key,
          title: 'Use my own AI key',
          subtitle:
              'Connect Anthropic, OpenAI, Google Gemini and more. Photos go to the provider you pick.',
          onTap: _useKey,
        ),
      ];

  List<Widget> _network(Color ink, Color sub, bool isDark) => [
        Text('Download the offline model',
            style: AppTypography.title1.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'About 309 MB. How should it download?',
          style: AppTypography.callout.copyWith(color: sub),
        ),
        const SizedBox(height: AppSpacing.md),
        _OptionTile(
          icon: PhosphorRegular.globe,
          title: 'Wi-Fi only',
          subtitle: 'Recommended. Starts as soon as you are on Wi-Fi.',
          primary: true,
          onTap: () => _start(false),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionTile(
          icon: PhosphorRegular.lightning,
          title: 'Use mobile data',
          subtitle: 'Starts now. This may use part of your data plan.',
          onTap: () => _start(true),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _step = _Step.choice),
            child: const Text('Back'),
          ),
        ),
      ];

  List<Widget> _progress(Color ink, Color sub, bool isDark) {
    final failed = _svc.state == OfflineModelState.failed;
    final waiting = _svc.isWaitingForWifi;
    final pct = (_svc.progress * 100).clamp(0, 100).toStringAsFixed(0);
    return [
      Text(
        failed
            ? 'Download stopped'
            : waiting
                ? 'Waiting for Wi-Fi'
                : 'Downloading the offline model',
        style: AppTypography.title1.copyWith(color: ink),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (failed)
        Text(_svc.error ?? 'The download did not finish.',
            style: AppTypography.callout.copyWith(color: AppColors.error))
      else if (waiting)
        Text('It will start by itself when this phone connects to Wi-Fi.',
            style: AppTypography.callout.copyWith(color: sub))
      else ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: _svc.bytesTotal == 0 ? null : _svc.progress,
            minHeight: 10,
            backgroundColor:
                isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _svc.bytesTotal == 0
              ? 'Starting…'
              : '${_mb(_svc.bytesDone)} MB of ${_mb(_svc.bytesTotal)} MB  ·  $pct%',
          style: AppTypography.callout.copyWith(color: sub),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          if (failed)
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() => _step = _Step.network),
                child: const Text('Try again'),
              ),
            )
          else
            Expanded(
              child: OutlinedButton(
                onPressed: _svc.cancel,
                child: const Text('Cancel'),
              ),
            ),
        ],
      ),
      if (!failed) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          'You can close this and keep using the app. The download continues.',
          style: AppTypography.caption.copyWith(color: sub),
        ),
      ],
    ];
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Material(
      color: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: primary
                  ? AppColors.accent
                  : (isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle),
              width: primary ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.headline.copyWith(color: ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTypography.footnote.copyWith(color: sub)),
                  ],
                ),
              ),
              Icon(PhosphorRegular.caretRight, color: sub, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

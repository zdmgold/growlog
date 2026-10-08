import '../services/ai/ai_settings.dart';
import '../widgets/ad_slot.dart';
import 'ai_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:growlog/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_model.dart';
import '../models/room_model.dart';
import '../providers/plant_provider.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import '../services/iap_service.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// NEW (Phase 5 cont., File 32). Fresh generation — nothing to recover
/// from the source transcript. Every service call below (ExportService,
/// PlantProvider, ThemeProvider, IAPService) is verified against real
/// source pulled from the transcript this session — none of it is
/// guessed.
///
/// UPDATE: `iap_service.dart` was reconciled to a one-time "Remove Ads"
/// non-consumable purchase (matching the agreed monetization model,
/// not the monthly/yearly subscription it was originally built for),
/// so the purchase button below is now real, not a placeholder.
class SettingsScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  final ThemeProvider themeProvider;
  final IAPService iapService;

  const SettingsScreen({
    super.key,
    required this.plantProvider,
    required this.themeProvider,
    required this.iapService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (e) {
      debugPrint('SettingsScreen._loadVersion error: $e');
    }
  }

  Future<void> _exportData() async {
    final l10n = AppLocalizations.of(context);
    try {
      final path = await ExportService.exportToJson(
        widget.plantProvider.value.plants,
        widget.plantProvider.rooms,
      );
      await ExportService.shareBackupFile(path);
    } catch (e) {
      debugPrint('SettingsScreen._exportData error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n?.failedToExportBackup ?? 'Failed to export backup'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final data =
          await ExportService.readBackupFile(result.files.single.path!);
      if (data == null) {
        throw Exception('Invalid backup file');
      }

      final roomsJson = (data['rooms'] as List<dynamic>? ?? []);
      final plantsJson = (data['plants'] as List<dynamic>? ?? []);

      for (final r in roomsJson) {
        await widget.plantProvider
            .addRoom(Room.fromJson(r as Map<String, dynamic>));
      }
      for (final p in plantsJson) {
        await widget.plantProvider
            .addPlant(Plant.fromJson(p as Map<String, dynamic>));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported')),
        );
      }
    } catch (e) {
      debugPrint('SettingsScreen._importData error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.failedToClearData ?? 'Import failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmClearAll() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.deletePlantTitle ?? 'Delete all data?'),
        content: Text(
            l10n?.deletePlantSimpleMessage ?? 'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(dialogContext);
              try {
                await widget.plantProvider.clearAll();
              } catch (e) {
                debugPrint('SettingsScreen._confirmClearAll error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          l10n?.failedToClearData ?? 'Failed to clear data'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseRemoveAds() async {
    HapticFeedback.mediumImpact();
    try {
      await widget.iapService.purchaseRemoveAds();
    } catch (e) {
      debugPrint('SettingsScreen._purchaseRemoveAds error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    HapticFeedback.lightImpact();
    try {
      await widget.iapService.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.iapService.value
                ? 'Purchases restored'
                : 'No previous purchases found'),
          ),
        );
      }
    } catch (e) {
      debugPrint('SettingsScreen._restorePurchases error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Scaffold(
      bottomNavigationBar: const SafeArea(top: false, child: AdSlot()),
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(PhosphorBold.arrowLeft, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n?.settingsTitle ?? 'Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
        ),
        children: [
          _SectionLabel(text: l10n?.theme ?? 'Theme'),
          ListenableBuilder(
            listenable: widget.themeProvider,
            builder: (context, _) {
              return _ThemeSelector(
                value: widget.themeProvider.value,
                isDark: isDark,
                labels: (
                  l10n?.themeSystem ?? 'System',
                  l10n?.themeLight ?? 'Light',
                  l10n?.themeDark ?? 'Dark',
                ),
                onChanged: (mode) {
                  HapticFeedback.lightImpact();
                  widget.themeProvider.setTheme(mode);
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel(text: 'AI'),
          ListenableBuilder(
            listenable: AiSettings.instance,
            builder: (context, _) {
              final ai = AiSettings.instance;
              return _Group(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: PhosphorRegular.key,
                    label: ai.isConfigured
                        ? 'AI connected: ${ai.provider?.name ?? ''}'
                        : 'Add your API key',
                    subtitle: ai.isConfigured
                        ? (ai.model ?? '')
                        : 'Needed for plant scans and chat',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiSetupScreen()),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: l10n?.backupRestore ?? 'Backup & Restore'),
          _Group(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: PhosphorRegular.uploadSimple,
                label: l10n?.exportData ?? 'Export Data',
                onTap: _exportData,
              ),
              _SettingsTile(
                icon: PhosphorRegular.downloadSimple,
                label: l10n?.importData ?? 'Import Data',
                onTap: _importData,
              ),
              _SettingsTile(
                icon: PhosphorRegular.trash,
                label: 'Clear All Data',
                danger: true,
                onTap: _confirmClearAll,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: l10n?.proFeatures ?? 'Remove Ads'),
          ListenableBuilder(
            listenable: widget.iapService,
            builder: (context, _) {
              if (widget.iapService.value) {
                return _Group(
                  isDark: isDark,
                  children: [
                    _SettingsTile(
                      icon: PhosphorFill.checkCircle,
                      success: true,
                      label: l10n?.adFree ?? 'Ad-free experience — active',
                    ),
                  ],
                );
              }
              return _Group(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: PhosphorRegular.prohibit,
                    label: widget.iapService.removeAdsPrice != null
                        ? '${l10n?.adFree ?? 'Remove Ads'} — ${widget.iapService.removeAdsPrice}'
                        : (l10n?.adFree ?? 'Remove Ads'),
                    onTap: _purchaseRemoveAds,
                  ),
                  _SettingsTile(
                    icon: PhosphorRegular.arrowClockwise,
                    label: l10n?.restorePurchases ?? 'Restore Purchases',
                    onTap: _restorePurchases,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: l10n?.about ?? 'About'),
          _Group(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: PhosphorRegular.info,
                label: l10n?.version ?? 'Version',
                trailing: Text(
                  _version,
                  style: AppTypography.footnote.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm, top: AppSpacing.sm, left: 4,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// A rounded card holding rows separated by hairlines.
class _Group extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _Group({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    final line = isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Divider(height: 1, thickness: 1, indent: 56, color: line));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode value;
  final bool isDark;
  final (String, String, String) labels;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSelector({
    required this.value,
    required this.isDark,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final items = [
      (ThemeMode.system, labels.$1, PhosphorRegular.slidersHorizontal),
      (ThemeMode.light, labels.$2, PhosphorRegular.sun),
      (ThemeMode.dark, labels.$3, PhosphorRegular.moon),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          for (final (mode, label, icon) in items)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == mode,
                label: '$label theme',
                child: Material(
                  color: value == mode
                      ? (isDark ? AppColors.bgTertiaryDark : AppColors.bgSecondary)
                      : Colors.transparent,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: value == mode
                          ? (isDark
                              ? AppColors.borderSubtleDark
                              : AppColors.borderSubtle)
                          : Colors.transparent,
                    ),
                  ),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onChanged(mode),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: value == mode
                                ? accent
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: AppTypography.callout.copyWith(
                              color: value == mode
                                  ? accent
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                              fontWeight: value == mode
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool danger;
  final bool success;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.danger = false,
    this.success = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final tertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;
    final err = isDark ? AppColors.errorDark : AppColors.error;
    final ok = isDark ? AppColors.successDark : AppColors.success;
    final iconColor = danger ? err : (success ? ok : sub);

    return Semantics(
      label: label,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: danger ? err : ink,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.footnote.copyWith(color: sub),
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? Icon(PhosphorBold.caretRight, size: 16, color: tertiary)
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

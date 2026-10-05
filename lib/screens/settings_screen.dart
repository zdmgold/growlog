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

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n?.settingsTitle ?? 'Settings',
          style: AppTypography.title1.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SectionLabel(text: l10n?.theme ?? 'Theme'),
          ListenableBuilder(
            listenable: widget.themeProvider,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.bgSecondaryDark
                      : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n?.themeSystem ?? 'System'),
                      icon: const Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n?.themeLight ?? 'Light'),
                      icon: const Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n?.themeDark ?? 'Dark'),
                      icon: const Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {widget.themeProvider.value},
                  onSelectionChanged: (selection) {
                    HapticFeedback.lightImpact();
                    widget.themeProvider.setTheme(selection.first);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: l10n?.backupRestore ?? 'Backup & Restore'),
          _SettingsTile(
            icon: Icons.upload_file,
            label: l10n?.exportData ?? 'Export Data',
            onTap: _exportData,
          ),
          _SettingsTile(
            icon: Icons.download,
            label: l10n?.importData ?? 'Import Data',
            onTap: _importData,
          ),
          _SettingsTile(
            icon: Icons.delete_forever,
            label: 'Clear All Data',
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            onTap: _confirmClearAll,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: l10n?.proFeatures ?? 'Remove Ads'),
          ListenableBuilder(
            listenable: widget.iapService,
            builder: (context, _) {
              if (widget.iapService.value) {
                return _SettingsTile(
                  icon: Icons.check_circle,
                  iconColor: AppColors.success,
                  label: l10n?.adFree ?? 'Ad-free experience — active',
                );
              }
              return Column(
                children: [
                  _SettingsTile(
                    icon: Icons.block,
                    label: widget.iapService.removeAdsPrice != null
                        ? '${l10n?.adFree ?? 'Remove Ads'} — ${widget.iapService.removeAdsPrice}'
                        : (l10n?.adFree ?? 'Remove Ads'),
                    onTap: _purchaseRemoveAds,
                  ),
                  _SettingsTile(
                    icon: Icons.restore,
                    label: l10n?.restorePurchases ?? 'Restore Purchases',
                    onTap: _restorePurchases,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: l10n?.about ?? 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: l10n?.version ?? 'Version',
            trailing: Text(
              _version,
              style: AppTypography.footnote
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: l10n?.privacyPolicy ?? 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: l10n?.termsOfService ?? 'Terms of Service',
            onTap: () {},
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.iconColor,
    this.labelColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: label,
      button: onTap != null,
      child: Material(
      color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.textTertiary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: labelColor ??
                        (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                  ),
                ),
              ),
              trailing ??
                  (onTap != null
                      ? const Icon(Icons.chevron_right,
                          color: AppColors.textTertiary)
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

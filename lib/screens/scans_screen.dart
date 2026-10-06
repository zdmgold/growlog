import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/scan_record.dart';
import '../providers/plant_provider.dart';
import '../services/scan_store.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import '../widgets/scan_widgets.dart';
import 'scan_screen.dart';

/// Every saved scan, newest first.
class ScansScreen extends StatelessWidget {
  final PlantProvider plantProvider;
  const ScansScreen({super.key, required this.plantProvider});

  Future<void> _confirmDelete(BuildContext context, ScanRecord s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this scan?'),
        content: Text('${s.commonName} will be removed from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await ScanStore.instance.delete(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(title: const Text('My scans')),
      body: ListenableBuilder(
        listenable: ScanStore.instance,
        builder: (context, _) {
          final scans = ScanStore.instance.scans;
          if (scans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorRegular.leaf, size: 48, color: sub),
                    const SizedBox(height: AppSpacing.md),
                    Text('No scans yet',
                        style: AppTypography.title1.copyWith(color: ink)),
                    const SizedBox(height: 4),
                    Text(
                      'Scan a plant from the home screen and it will appear here.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: sub),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
            ),
            itemCount: scans.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final s = scans[i];
              return Material(
                color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScanScreen(
                        plantProvider: plantProvider,
                        record: s,
                      ),
                    ),
                  ),
                  child: Ink(
                    padding: const EdgeInsets.all(AppSpacing.sm + 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderSubtleDark
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          child: SizedBox(
                            width: 84,
                            height: 84,
                            child: ScanThumb(scan: s),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.commonName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.title1.copyWith(
                                  color: ink,
                                  fontSize: 18,
                                ),
                              ),
                              if (s.latinName != null)
                                Text(
                                  s.latinName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.latin.copyWith(color: sub),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ScanHealthPill(health: s.health, compact: true),
                                  const SizedBox(width: 8),
                                  Text(
                                    scanDateLabel(s.createdAt),
                                    style: AppTypography.caption.copyWith(color: sub),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete scan',
                          icon: Icon(PhosphorRegular.trash, size: 20, color: sub),
                          onPressed: () => _confirmDelete(context, s),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/scan_record.dart';
import '../services/scan_store.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';
import 'scan_widgets.dart';

/// Horizontal strip of the latest scans. Hidden when there are none.
class RecentScansRow extends StatelessWidget {
  final void Function(ScanRecord scan) onOpen;
  const RecentScansRow({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ListenableBuilder(
      listenable: ScanStore.instance,
      builder: (context, _) {
        final scans = ScanStore.instance.scans.take(10).toList();
        if (scans.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 174,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: scans.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final s = scans[i];
              return SizedBox(
                width: 132,
                child: Semantics(
                  button: true,
                  label: context.l10n.scannedLabel(s.commonName, scanDateLabel(context, s.createdAt)),
                  child: Material(
                    color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      onTap: () => onOpen(s),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderSubtleDark
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadii.lg),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ScanThumb(scan: s),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm + 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.commonName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.title2.copyWith(
                                      color: ink,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    scanDateLabel(context, s.createdAt),
                                    style: AppTypography.caption.copyWith(color: sub),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

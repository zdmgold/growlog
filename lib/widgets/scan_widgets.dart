import 'dart:io';
import 'package:flutter/material.dart';
import 'package:growlog/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../l10n/l10n_ext.dart';
import '../models/scan_record.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

({Color color, IconData icon, String label}) scanHealthStyle(
  ScanHealth h,
  bool isDark,
  AppLocalizations l,
) {
  switch (h) {
    case ScanHealth.healthy:
      return (
        color: isDark ? AppColors.successDark : AppColors.success,
        icon: PhosphorFill.leaf,
        label: l.healthHealthy,
      );
    case ScanHealth.watch:
      return (
        color: isDark ? AppColors.warningDark : AppColors.watchText,
        icon: PhosphorFill.warning,
        label: l.healthWatch,
      );
    case ScanHealth.attention:
      return (
        color: isDark ? AppColors.errorDark : AppColors.attention,
        icon: PhosphorFill.firstAidKit,
        label: l.healthAttention,
      );
  }
}

class ScanHealthPill extends StatelessWidget {
  final ScanHealth health;
  final bool compact;
  const ScanHealthPill({super.key, required this.health, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final st = scanHealthStyle(health, isDark, context.l10n);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: st.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(st.icon, size: compact ? 13 : 16, color: st.color),
          const SizedBox(width: 6),
          Text(
            st.label,
            style: AppTypography.caption.copyWith(
              color: st.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo of a saved scan, with a quiet placeholder if the file is gone.
class ScanThumb extends StatelessWidget {
  final ScanRecord scan;
  const ScanThumb({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.file(
      File(scan.imagePath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
        alignment: Alignment.center,
        child: Icon(
          PhosphorRegular.leaf,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
      ),
    );
  }
}

String scanDateLabel(BuildContext context, DateTime d) {
  final l = context.l10n;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return l.today;
  if (diff == 1) return l.yesterday;
  if (diff < 7) return l.daysAgo(diff);
  return DateFormat.MMMd(Localizations.localeOf(context).toString()).format(d);
}

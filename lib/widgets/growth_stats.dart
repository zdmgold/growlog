import 'package:flutter/material.dart';
import '../models/measurement_model.dart';
import '../utils/constants.dart';

class GrowthStats extends StatelessWidget {
  final List<Measurement> measurements;

  const GrowthStats({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (measurements.length < 2) {
      return const SizedBox.shrink();
    }

    final sorted = List<Measurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first;
    final latest = sorted.last;

    final heightDiff = (latest.height != null && first.height != null)
        ? latest.height! - first.height!
        : null;
    final leafDiff = (latest.leafCount != null && first.leafCount != null)
        ? latest.leafCount! - first.leafCount!
        : null;

    final days = latest.date.difference(first.date).inDays;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Growth over ${days < 30 ? '$days days' : '${(days / 30).floor()} months'}',
            style: AppTypography.callout.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (heightDiff != null)
            _StatRow(
              icon: Icons.height,
              label: 'Height',
              value: '${heightDiff >= 0 ? '+' : ''}${heightDiff.toStringAsFixed(1)} cm',
              positive: heightDiff >= 0,
            ),
          if (leafDiff != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _StatRow(
              icon: Icons.eco,
              label: 'Leaves',
              value: '${leafDiff >= 0 ? '+' : ''}$leafDiff',
              positive: leafDiff >= 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool positive;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.title2.copyWith(
            color: positive ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

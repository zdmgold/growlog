import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/measurement_model.dart';
import '../utils/constants.dart';

class MeasurementChart extends StatelessWidget {
  final List<Measurement> measurements;
  final String title;
  final bool showHeight;
  final bool showLeafCount;

  const MeasurementChart({
    super.key,
    required this.measurements,
    required this.title,
    this.showHeight = true,
    this.showLeafCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (measurements.length < 2) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Center(
          child: Text(
            'Add more measurements to see trends',
            style: AppTypography.callout.copyWith(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    final sorted = List<Measurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    final heightSpots = <FlSpot>[];
    final leafSpots = <FlSpot>[];

    for (int i = 0; i < sorted.length; i++) {
      if (showHeight && sorted[i].height != null) {
        heightSpots.add(FlSpot(i.toDouble(), sorted[i].height!));
      }
      if (showLeafCount && sorted[i].leafCount != null) {
        leafSpots.add(FlSpot(i.toDouble(), sorted[i].leafCount!.toDouble()));
      }
    }

    return Container(
      height: 240,
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
            title,
            style: AppTypography.title2.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                        );
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  if (heightSpots.isNotEmpty)
                    LineChartBarData(
                      spots: heightSpots,
                      isCurved: true,
                      color: AppColors.accent,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withOpacity(0.1),
                      ),
                    ),
                  if (leafSpots.isNotEmpty)
                    LineChartBarData(
                      spots: leafSpots,
                      isCurved: true,
                      color: AppColors.warning,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

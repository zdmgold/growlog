import 'package:flutter/material.dart';
import '../models/care_log_model.dart';
import '../utils/constants.dart';

class CareCalendar extends StatelessWidget {
  final List<CareLog> careLogs;
  final DateTime month;

  const CareCalendar({
    super.key,
    required this.careLogs,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
            return SizedBox(
              width: 36,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) return const SizedBox.shrink();
            final day = index - firstWeekday + 1;
            final date = DateTime(month.year, month.month, day);
            final dayLogs = careLogs.where((l) {
              return l.date.year == date.year &&
                  l.date.month == date.month &&
                  l.date.day == date.day;
            }).toList();

            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: dayLogs.isNotEmpty
                    ? AppColors.accent.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: AppTypography.footnote.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: dayLogs.isNotEmpty ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (dayLogs.isNotEmpty)
                    Wrap(
                      spacing: 2,
                      children: dayLogs.take(3).map((l) {
                        return Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: l.type.color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

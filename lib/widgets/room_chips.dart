import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// Horizontal room filter. `rooms` holds (id, name) pairs; null selects "All".
class RoomChips extends StatelessWidget {
  final List<(String, String)> rooms;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const RoomChips({
    super.key,
    required this.rooms,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
        ),
        children: [
          _chip(context, 'All', selected == null, () => onSelect(null)),
          for (final (id, name) in rooms)
            _chip(context, name, selected == id, () => onSelect(id)),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = active
        ? (isDark ? AppColors.accentLight : AppColors.forest)
        : (isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary);
    final fg = active
        ? (isDark ? AppColors.bgPrimaryDark : Colors.white)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: active,
        label: '$label rooms filter',
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: BorderSide(
              color: active
                  ? Colors.transparent
                  : (isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle),
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.callout.copyWith(
                    color: fg,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

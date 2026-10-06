import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// Bottom dock: Home, Garden, a centre Scan button, Schedule and Scans.
class AppDock extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onScan;

  const AppDock({
    super.key,
    required this.index,
    required this.onTab,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
          ),
        ),
      ),
      child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _Item(
                label: 'Home',
                icon: PhosphorRegular.house,
                activeIcon: PhosphorFill.house,
                selected: index == 0,
                onTap: () => onTab(0),
              ),
              _Item(
                label: 'Garden',
                icon: PhosphorRegular.plant,
                activeIcon: PhosphorFill.plant,
                selected: index == 1,
                onTap: () => onTab(1),
              ),
              Expanded(child: Center(child: _ScanButton(onTap: onScan))),
              _Item(
                label: 'Schedule',
                icon: PhosphorRegular.calendarCheck,
                activeIcon: PhosphorFill.calendarCheck,
                selected: index == 2,
                onTap: () => onTab(2),
              ),
              _Item(
                label: 'Scans',
                icon: PhosphorRegular.clock,
                activeIcon: PhosphorFill.clock,
                selected: index == 3,
                onTap: () => onTab(3),
              ),
            ],
          ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  const _Item({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? AppColors.accentLight : AppColors.accent)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: () {
            if (!selected) HapticFeedback.selectionClick();
            onTap();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, size: 26, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.accentLight : AppColors.accent;
    return Semantics(
      button: true,
      label: 'Scan a plant',
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Icon(
              PhosphorFill.camera,
              size: 28,
              color: isDark ? AppColors.bgPrimaryDark : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// The main call to action on the home screen.
class ScanHeroCard extends StatelessWidget {
  final bool hasPlants;
  final VoidCallback onPrimary;
  final VoidCallback onGallery;
  final VoidCallback onHistory;
  final VoidCallback onPaul;

  const ScanHeroCard({
    super.key,
    required this.hasPlants,
    required this.onPrimary,
    required this.onGallery,
    required this.onHistory,
    required this.onPaul,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = context.l10n;
    final colors = isDark
        ? const [Color(0xFF1B3126), Color(0xFF12221A)]
        : const [Color(0xFF2E7D4F), Color(0xFF1F3A2D)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(
          color: isDark
              ? AppColors.accentLight.withOpacity(0.28)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.accentLight : AppColors.forest)
                .withOpacity(isDark ? 0.10 : 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: CustomPaint(
          painter: const _RingsPainter(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorFill.leaf, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        l.heroBadge,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.scanAPlant,
                  style: AppTypography.display.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasPlants
                      ? l.heroSubWithPlants
                      : l.heroSubNoPlants,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  button: true,
                  label: l.openCamera,
                  child: Material(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      onTap: onPrimary,
                      child: SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorFill.camera,
                              size: 22,
                              color: AppColors.forest,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l.openCamera,
                              style: AppTypography.title2.copyWith(
                                color: AppColors.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Chip(
                      icon: PhosphorRegular.image,
                      label: l.gallery,
                      onTap: onGallery,
                    ),
                    _Chip(
                      icon: PhosphorRegular.clock,
                      label: l.myScans,
                      onTap: onHistory,
                    ),
                    _Chip(
                      icon: PhosphorRegular.chatCircleDots,
                      label: l.askPaul,
                      onTap: onPaul,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Chip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.callout.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft concentric rings in the top-right corner.
class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withOpacity(0.07);
    final c = Offset(size.width * 0.95, size.height * 0.04);
    for (final r in [60.0, 100.0, 140.0, 180.0]) {
      canvas.drawCircle(c, r, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

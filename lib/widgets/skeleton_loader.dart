import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// NEW FILE (Fix Phase B, premium feature #1): reusable shimmer
/// placeholder shown while `PlantProvider.imageExists()` hasn't
/// resolved yet for a given photo path, replacing the blank/icon
/// container that used to show during that (usually brief) window.
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary;
    final highlight = isDark
        ? AppColors.bgSecondaryDark.withOpacity(0.6)
        : Colors.white.withOpacity(0.6);

    return ClipRRect(
      borderRadius: widget.borderRadius ??
          BorderRadius.circular(AppRadii.md),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [base, highlight, base],
                  stops: const [0.0, 0.5, 1.0],
                  transform:
                      GradientRotation(_controller.value * 2 * 3.14159),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

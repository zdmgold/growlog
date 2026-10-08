import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/care_log_model.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// True when the phone's "remove animations" setting is on.
bool reduceMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;

/// An arc that draws itself around an icon: green, amber or terracotta.
class HealthRing extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;
  final double fill;

  const HealthRing({
    super.key,
    required this.color,
    required this.icon,
    this.size = 68,
    this.fill = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final instant = reduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: instant ? fill : 0, end: fill),
      duration: instant ? Duration.zero : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(color: color, progress: t),
            child: Center(child: Icon(icon, color: color, size: size * 0.4)),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double progress;
  _RingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = color.withOpacity(0.16);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// A leaf that unfurls from the stem: scales up while rotating into place,
/// then fades. Shown once after "Save to garden".
class LeafUnfurl extends StatefulWidget {
  final VoidCallback onDone;
  const LeafUnfurl({super.key, required this.onDone});

  @override
  State<LeafUnfurl> createState() => _LeafUnfurlState();
}

class _LeafUnfurlState extends State<LeafUnfurl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final grow = Curves.easeOutBack.transform((t / 0.65).clamp(0.0, 1.0));
            final turn = (1 - Curves.easeOutCubic.transform((t / 0.65).clamp(0.0, 1.0))) * -0.45;
            final fade = t < 0.7 ? 1.0 : 1 - ((t - 0.7) / 0.3);
            return Opacity(
              opacity: fade.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: turn,
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scale: grow,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(PhosphorFill.leaf, size: 60, color: accent),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The round "done" check. A tap plays a short press, and for watering a
/// drop falls and ripples, then [onDone] runs.
class DoneCheckButton extends StatefulWidget {
  final CareType type;
  final double size;
  final Color background;
  final Color foreground;
  final String semanticLabel;
  final VoidCallback onDone;

  const DoneCheckButton({
    super.key,
    required this.type,
    required this.background,
    required this.foreground,
    required this.semanticLabel,
    required this.onDone,
    this.size = 48,
  });

  @override
  State<DoneCheckButton> createState() => _DoneCheckButtonState();
}

class _DoneCheckButtonState extends State<DoneCheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_busy) return;
    if (reduceMotion(context)) {
      widget.onDone();
      return;
    }
    _busy = true;
    await _c.forward(from: 0);
    if (mounted) {
      _busy = false;
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWater = widget.type == CareType.water;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final press = math.sin(_c.value * math.pi);
                return Transform.scale(scale: 1 + 0.18 * press, child: child);
              },
              child: Material(
                color: widget.background,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _tap,
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Icon(
                      PhosphorBold.check,
                      size: widget.size * 0.45,
                      color: widget.foreground,
                    ),
                  ),
                ),
              ),
            ),
            if (isWater)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final t = _c.value;
                    if (t == 0) return const SizedBox.shrink();
                    final fall = Curves.easeIn.transform((t / 0.7).clamp(0.0, 1.0));
                    final ripple = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Opacity(
                          opacity: t < 0.7 ? 1 : 0,
                          child: Transform.translate(
                            offset: Offset(0, -26 + 26 * fall),
                            child: Icon(
                              PhosphorFill.drop,
                              size: 16,
                              color: AppColors.water,
                            ),
                          ),
                        ),
                        if (ripple > 0)
                          Container(
                            width: widget.size * (0.5 + 0.9 * ripple),
                            height: widget.size * (0.5 + 0.9 * ripple),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.water.withOpacity(0.6 * (1 - ripple)),
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

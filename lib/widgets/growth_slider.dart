import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_entry_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'skeleton_loader.dart';

class GrowthSlider extends StatefulWidget {
  final PhotoEntry before;
  final PhotoEntry after;
  // SURGICAL ADDITION (Fix Phase B, feature #5 — this was missed when
  // the drag-math bug was fixed in Fix Phase A): needed to read the
  // async image-existence cache instead of File(path).existsSync().
  final PlantProvider plantProvider;

  const GrowthSlider({
    super.key,
    required this.before,
    required this.after,
    required this.plantProvider,
  });

  @override
  State<GrowthSlider> createState() => _GrowthSliderState();
}

class _GrowthSliderState extends State<GrowthSlider> {
  double _position = 0.5;
  bool _isDragging = false;

  // SURGICAL FIX: key on the full-size comparison stack. The drag handle
  // itself is only 48x48, so its own `details.localPosition` (as used
  // previously) only ever ranges over that 48px box — the slider could
  // never reach the edges. This key lets us find the *outer* full-width
  // RenderBox and convert the handle's global drag position into local
  // coordinates relative to that, exactly like the outer tap handler
  // already does correctly via `localPosition` on the full-size
  // GestureDetector.
  final GlobalKey _comparisonKey = GlobalKey();

  void _updatePositionFromGlobal(Offset globalPosition, double width) {
    final renderBox =
        _comparisonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final local = renderBox.globalToLocal(globalPosition);
    setState(() {
      _position = (local.dx / width).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          key: _comparisonKey,
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(widget.after.path, width, height),
                      ClipRect(
                        clipper: _BeforeClipper(position: _position),
                        child: _buildImage(widget.before.path, width, height),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                setState(() {
                  _position =
                      (details.localPosition.dx / width).clamp(0.0, 1.0);
                });
              },
              child: Stack(
                children: [
                  Positioned(
                    left: (_position * width) - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 3, color: AppColors.accent),
                  ),
                  Positioned(
                    left: (_position * width) - 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: (details) {
                          setState(() => _isDragging = true);
                          _updatePositionFromGlobal(
                              details.globalPosition, width);
                        },
                        onHorizontalDragUpdate: (details) {
                          _updatePositionFromGlobal(
                              details.globalPosition, width);
                        },
                        onHorizontalDragEnd: (_) =>
                            setState(() => _isDragging = false),
                        child: AnimatedContainer(
                          // FIX: feature #7 (reduce motion) was approved
                          // in the original plan and marked done, but
                          // this check was never actually added — a
                          // real regression caught during the blueprint
                          // audit, not new scope.
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : AppDurations.fast,
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isDragging
                                ? AppColors.accentLight
                                : AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.compare_arrows,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    child: _DateLabel(
                      text: DateFormatter.shortDate(widget.before.date),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _DateLabel(
                      text: DateFormatter.shortDate(widget.after.date),
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// SURGICAL FIX: previously called `File(path).existsSync()` directly
  /// in build(). Now reads the async cache: null (not checked yet)
  /// shows a SkeletonLoader sized to match, false/missing shows the
  /// same "image not supported" placeholder as before, true shows the
  /// image.
  Widget _buildImage(String path, double width, double height) {
    final exists = widget.plantProvider.imageExists(path);
    if (exists == null) {
      return SkeletonLoader(
        width: width,
        height: height,
        borderRadius: BorderRadius.zero,
      );
    }
    if (exists == false) {
      return Container(
        color: AppColors.bgTertiary,
        width: width,
        height: height,
        child: const Icon(Icons.image_not_supported,
            color: AppColors.textTertiary),
      );
    }
    return Image.file(File(path), fit: BoxFit.cover, width: width, height: height);
  }
}

class _BeforeClipper extends CustomClipper<Rect> {
  final double position;
  _BeforeClipper({required this.position});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_BeforeClipper old) => old.position != position;
}

class _DateLabel extends StatelessWidget {
  final String text;
  final Alignment alignment;

  const _DateLabel({required this.text, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

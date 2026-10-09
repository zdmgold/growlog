import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';

/// Popped by [CameraScreen] when the user captured or picked a photo.
class CameraResult {
  final String path;
  const CameraResult(this.path);
}

const int _maxSide = 1400;

/// Fixes EXIF orientation and shrinks a captured JPEG so it uploads quickly.
/// Top-level so it can run in a background isolate via [compute].
Future<String> _shrinkJpeg(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeJpg(bytes);
  if (decoded == null) return path;
  var out = img.bakeOrientation(decoded);
  if (out.width > _maxSide || out.height > _maxSide) {
    out = out.width >= out.height
        ? img.copyResize(out, width: _maxSide)
        : img.copyResize(out, height: _maxSide);
  }
  final dot = path.lastIndexOf('.');
  final target = '${dot > 0 ? path.substring(0, dot) : path}_scan.jpg';
  await File(target).writeAsBytes(img.encodeJpg(out, quality: 85));
  return target;
}

/// Full-screen in-app camera with a scan frame. Pops a [CameraResult].
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  String? _error;
  FlashMode _flash = FlashMode.off;
  bool _busy = false;
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweep.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c == null) return;
      _controller = null;
      if (mounted) setState(() {});
      c.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _setup();
    }
  }

  Future<void> _setup() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (mounted) setState(() => _error = 'No camera was found on this device.');
        return;
      }
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : null,
      );
      await controller.initialize();
      await controller.setFlashMode(_flash);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('Denied') || e.code.contains('Restricted');
      setState(() {
        _error = denied
            ? 'Camera access is turned off. Allow it in your phone settings, or pick a photo instead.'
            : 'The camera could not start. You can pick a photo instead.';
      });
    } catch (e) {
      debugPrint('CameraScreen._setup error: $e');
      if (mounted) {
        setState(() => _error = 'The camera could not start. You can pick a photo instead.');
      }
    }
  }

  Future<void> _cycleFlash() async {
    final c = _controller;
    if (c == null) return;
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    try {
      await c.setFlashMode(next);
      if (mounted) setState(() => _flash = next);
    } on CameraException catch (e) {
      debugPrint('CameraScreen flash error: ${e.code}');
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final shot = await c.takePicture();
      final path = await compute(_shrinkJpeg, shot.path);
      if (!mounted) return;
      Navigator.pop(context, CameraResult(path));
    } on CameraException catch (e) {
      debugPrint('CameraScreen capture error: ${e.code}');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'The photo could not be taken. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('CameraScreen capture error: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxSide.toDouble(),
    );
    if (picked != null && mounted) {
      Navigator.pop(context, CameraResult(picked.path));
    }
  }

  Future<void> _useSystemCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: _maxSide.toDouble(),
    );
    if (picked != null && mounted) {
      Navigator.pop(context, CameraResult(picked.path));
    }
  }

  IconData get _flashIcon => switch (_flash) {
        FlashMode.off => PhosphorRegular.lightningSlash,
        FlashMode.auto => PhosphorRegular.lightningA,
        _ => PhosphorFill.lightning,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          if (_controller != null && _error == null) _buildFrame(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                if (_error == null) _buildHint(),
                _buildBottomBar(),
              ],
            ),
          ),
          if (_error != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * c.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(child: CameraPreview(c)),
      ),
    );
  }

  Widget _buildFrame() {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth * 0.78;
          final h = math.min(w * 1.15, box.maxHeight * 0.52);
          final rect = Rect.fromCenter(
            center: Offset(box.maxWidth / 2, box.maxHeight * 0.42),
            width: w,
            height: h,
          );
          return CustomPaint(
            size: Size(box.maxWidth, box.maxHeight),
            painter: _ScanFramePainter(rect: rect, sweep: _sweep),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Row(
        children: [
          _RoundButton(
            icon: PhosphorRegular.x,
            label: 'Close camera',
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          if (_controller != null)
            _RoundButton(
              icon: _flashIcon,
              label: 'Flash',
              onTap: _cycleFlash,
            ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: const Text(
          'Fill the frame with a leaf or the whole plant',
          style: TextStyle(
            fontFamily: AppTypography.sans,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundButton(
            icon: PhosphorRegular.image,
            label: 'Choose from gallery',
            onTap: _pickFromGallery,
          ),
          _Shutter(busy: _busy, onTap: _capture),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: AppColors.bgPrimaryDark.withOpacity(0.96),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorRegular.cameraSlash,
              size: 56,
              color: AppColors.accentLight,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.sans,
                fontSize: 16,
                height: 1.5,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pickFromGallery,
                child: const Text('Choose from gallery'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _useSystemCamera,
              child: const Text('Use the phone camera app'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const _Shutter({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take photo',
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: busy ? AppColors.textTertiaryDark : AppColors.accentLight,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Dimmed surround, rounded corner brackets and a soft scanning line.
class _ScanFramePainter extends CustomPainter {
  final Rect rect;
  final Animation<double> sweep;

  _ScanFramePainter({required this.rect, required this.sweep})
      : super(repaint: sweep);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(frame)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black.withOpacity(0.32));

    final bracket = Paint()
      ..color = AppColors.accentLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const arm = 34.0;
    const r = 28.0;
    final l = rect.left, t = rect.top, rt = rect.right, b = rect.bottom;

    void corner(Offset corner, double dx, double dy) {
      final p = Path()
        ..moveTo(corner.dx, corner.dy + dy * arm)
        ..lineTo(corner.dx, corner.dy + dy * r)
        ..quadraticBezierTo(corner.dx, corner.dy, corner.dx + dx * r, corner.dy)
        ..lineTo(corner.dx + dx * arm, corner.dy);
      canvas.drawPath(p, bracket);
    }

    corner(Offset(l, t), 1, 1);
    corner(Offset(rt, t), -1, 1);
    corner(Offset(l, b), 1, -1);
    corner(Offset(rt, b), -1, -1);

    final y = rect.top + 14 + (rect.height - 28) * Curves.easeInOut.transform(sweep.value);
    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.accentLight.withOpacity(0),
          AppColors.accentLight.withOpacity(0.9),
          AppColors.accentLight.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, y - 1, rect.width, 2))
      ..strokeWidth = 2;
    canvas.drawLine(Offset(rect.left + 18, y), Offset(rect.right - 18, y), line);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter old) => old.rect != rect;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/plant_provider.dart';
import '../screens/ai_setup_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/scan_screen.dart';
import '../services/ai/ai_settings.dart';

/// Starts a scan from anywhere: checks the AI key, gets a photo, opens the
/// result screen.
class ScanLauncher {
  ScanLauncher._();

  static bool _ensureAi(BuildContext context) {
    if (AiSettings.instance.isConfigured) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add your API key to scan plants.')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiSetupScreen()),
    );
    return false;
  }

  static void _open(
    BuildContext context,
    PlantProvider provider,
    String imagePath,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          plantProvider: provider,
          imagePath: imagePath,
        ),
      ),
    );
  }

  static Future<void> camera(
    BuildContext context,
    PlantProvider provider,
  ) async {
    HapticFeedback.mediumImpact();
    if (!_ensureAi(context)) return;
    final result = await Navigator.push<CameraResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CameraScreen(),
      ),
    );
    if (result == null || !context.mounted) return;
    _open(context, provider, result.path);
  }

  static Future<void> gallery(
    BuildContext context,
    PlantProvider provider,
  ) async {
    if (!_ensureAi(context)) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
    );
    if (picked == null || !context.mounted) return;
    _open(context, provider, picked.path);
  }
}

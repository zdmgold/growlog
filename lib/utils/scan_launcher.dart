import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/l10n_ext.dart';
import '../providers/plant_provider.dart';
import '../screens/offline_identify_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/scan_screen.dart';
import '../services/ai/ai_settings.dart';
import '../services/offline/offline_model_service.dart';
import '../widgets/identifier_gate_sheet.dart';

/// Starts a scan from anywhere: checks the AI key, gets a photo, opens the
/// result screen.
class ScanLauncher {
  ScanLauncher._();

  /// Identification is ready when the offline model is installed or an AI key is
  /// connected. Otherwise a sheet offers to download the model or connect a key.
  static Future<bool> _ensureIdentifier(BuildContext context) async {
    bool ready() =>
        OfflineModelService.instance.isInstalled ||
        AiSettings.instance.isConfigured;
    if (ready()) return true;
    final ok = await showIdentifierGate(context);
    return ok && ready();
  }

  static void _open(
    BuildContext context,
    PlantProvider provider,
    String imagePath,
  ) {
    // The offline model is the default; the AI key is the second opinion.
    final offline = OfflineModelService.instance.isInstalled;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => offline
            ? OfflineIdentifyScreen(
                plantProvider: provider,
                imagePath: imagePath,
              )
            : ScanScreen(
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
    if (!await _ensureIdentifier(context)) return;
    if (!context.mounted) return;
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
    if (!await _ensureIdentifier(context)) return;
    if (!context.mounted) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
    );
    if (picked == null || !context.mounted) return;
    _open(context, provider, picked.path);
  }
}

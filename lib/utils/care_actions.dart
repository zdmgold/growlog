import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/care_log_model.dart';
import '../providers/plant_provider.dart';
import 'care_due.dart';
import 'constants.dart';

/// Logs a due care task as done, with feedback. Shared by the home tiles and
/// the Schedule hub.
Future<void> markCareDone(
  BuildContext context,
  PlantProvider provider,
  DueCare item,
) async {
  HapticFeedback.mediumImpact();
  final log = CareLog(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    plantId: item.plant.id,
    type: item.type,
    date: DateTime.now(),
  );
  final messenger = ScaffoldMessenger.of(context);
  try {
    await provider.addCareLog(item.plant.id, log);
    messenger.showSnackBar(
      SnackBar(content: Text('${item.type.label} logged for ${item.plant.name}')),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not save that. Please try again.'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

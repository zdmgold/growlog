import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/care_log_model.dart';
import '../providers/plant_provider.dart';
import 'care_due.dart';
import '../l10n/l10n_ext.dart';
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
  final l = context.l10n;
  final careName = context.careLabel(item.type);
  try {
    await provider.addCareLog(item.plant.id, log);
    messenger.showSnackBar(
      SnackBar(content: Text(l.careLoggedSnackbar(careName, item.plant.name))),
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.couldNotSaveRetry),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

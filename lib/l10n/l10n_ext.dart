import 'package:flutter/widgets.dart';
import '../models/care_log_model.dart';
import 'app_localizations.dart';

/// Short access to the generated translations: `context.l10n.navHome`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// The translated name of a care type (Water, Fertilize, ...).
  String careLabel(CareType t) {
    final l = l10n;
    switch (t) {
      case CareType.water:
        return l.careTypeWater;
      case CareType.fertilize:
        return l.careTypeFertilize;
      case CareType.mist:
        return l.careTypeMist;
      case CareType.repot:
        return l.careTypeRepot;
      case CareType.prune:
        return l.careTypePrune;
      case CareType.treat:
        return l.careTypeTreat;
    }
  }
}

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

/// The app language as an English name, used to ask the AI to answer in it.
String appLanguageName(BuildContext c) {
  switch (Localizations.localeOf(c).languageCode) {
    case 'es':
      return 'Spanish';
    case 'fr':
      return 'French';
    case 'de':
      return 'German';
    case 'pt':
      return 'Portuguese';
    case 'ar':
      return 'Arabic';
    case 'hi':
      return 'Hindi';
    case 'ja':
      return 'Japanese';
    case 'ko':
      return 'Korean';
    case 'zh':
      return 'Chinese';
    case 'he':
      return 'Hebrew';
    default:
      return 'English';
  }
}

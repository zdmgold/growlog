import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Short access to the generated translations: `context.l10n.navHome`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

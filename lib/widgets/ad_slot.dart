import 'package:flutter/cupertino.dart';
import 'banner_ad_widget.dart';

/// Shared bottom ad slot used on every screen.
///
/// Owns only the top-level hide logic:
///   1. The user has purchased ad removal (mirrors [PurchaseProvider]).
///   2. A software keyboard is visible (MediaQuery.viewInsetsOf bottom > 0).
///
/// Adds the 4dp strip under the ad (Atrament carries this in its shared
/// AppScaffold; Peshat has no AppScaffold, so it lives here). The strip sits
/// on the page background and is invisible against the scaffold.
class AdSlot extends StatelessWidget {
  const AdSlot({super.key});

  static final ValueNotifier<bool> _purchased = ValueNotifier<bool>(false);

  /// True after the Remove Ads purchase. Added for GrowLog's interstitials.
  static bool get isPurchased => _purchased.value;

  /// Called from main.dart whenever the purchase state changes.
  static void setPurchased(bool value) => _purchased.value = value;

  @override
  Widget build(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    return ValueListenableBuilder<bool>(
      valueListenable: _purchased,
      builder: (context, purchased, _) {
        if (purchased || keyboardUp) return const SizedBox.shrink();
        return const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: BannerAdWidget(),
        );
      },
    );
  }
}

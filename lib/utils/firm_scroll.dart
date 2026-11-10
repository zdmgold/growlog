import 'package:flutter/material.dart';

/// Scrolling that feels solid. Material 3 stretches the whole page when you hit
/// the top or bottom on Android 12 and newer, which reads as shaky. This keeps
/// the content still at the edges. iOS keeps its own native bounce.
class FirmScrollBehavior extends MaterialScrollBehavior {
  const FirmScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
    }
    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

import 'package:flutter/material.dart';

/// A tab title that shrinks to fit instead of being cut off at large text sizes.
class TabLabel extends StatelessWidget {
  final String text;
  const TabLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, softWrap: false),
      );
}

import 'package:flutter/material.dart';

class AppColors {
  // Field Journal: warm paper surfaces, deep forest ink, chlorophyll accents.
  static const Color bgPrimary = Color(0xFFF6F1E7);
  static const Color bgSecondary = Color(0xFFFCFAF5);
  static const Color bgTertiary = Color(0xFFEDE6D6);

  // Night greenhouse.
  static const Color bgPrimaryDark = Color(0xFF0E1A14);
  static const Color bgSecondaryDark = Color(0xFF16251D);
  static const Color bgTertiaryDark = Color(0xFF1F3329);

  static const Color accent = Color(0xFF2E7D4F);
  static const Color accentLight = Color(0xFF5CC77A);
  static const Color accentDark = Color(0xFF1F5C38);
  static const Color chlorophyll = Color(0xFF4CAF50);
  static const Color forest = Color(0xFF1F3A2D);

  static const Color textPrimary = Color(0xFF1F3A2D);
  static const Color textSecondary = Color(0xFF4A5F52);
  static const Color textTertiary = Color(0xFF5E6E63);

  static const Color textPrimaryDark = Color(0xFFF0EBDD);
  static const Color textSecondaryDark = Color(0xFFB9C6BB);
  static const Color textTertiaryDark = Color(0xFF8A9A8E);

  static const Color borderSubtle = Color(0xFFE3DBC9);
  static const Color borderSubtleDark = Color(0xFF2A4034);
  static const Color borderFocus = Color(0xFF2E7D4F);
  static const Color borderFocusDark = Color(0xFF5CC77A);

  static const Color error = Color(0xFFB4432B);
  static const Color errorDark = Color(0xFFE0745A);
  static const Color success = Color(0xFF2E7D4F);
  static const Color successDark = Color(0xFF5CC77A);
  static const Color warning = Color(0xFFE0A33A);
  static const Color warningDark = Color(0xFFE8B45A);

  // Plant health states.
  static const Color healthy = Color(0xFF4CAF50);
  static const Color watch = Color(0xFFE0A33A);
  static const Color attention = Color(0xFFB4532E);
  static const Color watchText = Color(0xFF7A5410);

  // Care types: a botanical palette instead of saturated primaries.
  static const Color water = Color(0xFF3F8EA6);
  static const Color fertilize = Color(0xFFA7803B);
  static const Color mist = Color(0xFF6FA3A0);
  static const Color repot = Color(0xFF8A5A44);
  static const Color prune = Color(0xFF7A9A3A);
  static const Color treat = Color(0xFFB4432B);
}

class AppRadii {
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double pill = 999.0;
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class AppTypography {
  static const String serif = 'Fraunces';
  static const String sans = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: serif,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: -0.5,
  );
  static const TextStyle headline = TextStyle(
    fontFamily: serif,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.3,
  );
  static const TextStyle title1 = TextStyle(
    fontFamily: serif,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );
  static const TextStyle title2 = TextStyle(
    fontFamily: sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle callout = TextStyle(
    fontFamily: sans,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static const TextStyle footnote = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.2,
  );
  // Latin names under plant titles: small italic serif.
  static const TextStyle latin = TextStyle(
    fontFamily: serif,
    fontSize: 13,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}

class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration screenPush = Duration(milliseconds: 350);
  static const Duration screenPop = Duration(milliseconds: 280);
  static const Duration sheetPresent = Duration(milliseconds: 400);
  static const Duration themeToggle = Duration(milliseconds: 200);
}

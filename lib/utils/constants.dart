import 'package:flutter/material.dart';

class AppColors {
  static const Color bgPrimary = Color(0xFFFAFAF8);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgTertiary = Color(0xFFF2F2F0);

  static const Color bgPrimaryDark = Color(0xFF0A0A0A);
  static const Color bgSecondaryDark = Color(0xFF1C1C1E);
  static const Color bgTertiaryDark = Color(0xFF2C2C2E);

  static const Color accent = Color(0xFF2D6A4F);
  static const Color accentLight = Color(0xFF40916C);
  static const Color accentDark = Color(0xFF1B4332);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF3C3C43);
  static const Color textTertiary = Color(0xFF8E8E93);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFEBEBF5);

  static const Color borderSubtle = Color(0xFFE5E5EA);
  static const Color borderSubtleDark = Color(0xFF38383A);
  static const Color borderFocus = Color(0xFF2D6A4F);
  static const Color borderFocusDark = Color(0xFF40916C);

  static const Color error = Color(0xFFFF3B30);
  static const Color errorDark = Color(0xFFFF453A);
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF30D158);
  static const Color warning = Color(0xFFFF9500);
  static const Color warningDark = Color(0xFFFF9F0A);

  static const Color water = Color(0xFF4CC9F0);
  static const Color fertilize = Color(0xFFF72585);
  static const Color mist = Color(0xFF7209B7);
  static const Color repot = Color(0xFF3A0CA3);
  static const Color prune = Color(0xFFF48C06);
  static const Color treat = Color(0xFFE63946);
}

class AppRadii {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
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
  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle title1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle title2 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
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

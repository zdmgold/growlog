import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:growlog/l10n/app_localizations.dart';
import 'providers/plant_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/local_storage.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'widgets/ad_slot.dart';
import 'services/ai/ai_settings.dart';
import 'services/interstitial_service.dart';
import 'services/scan_store.dart';
import 'services/iap_service.dart';
import 'utils/error_handler.dart';
import 'utils/constants.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorHandler.install();

  await NotificationService.initialize();
  await AiSettings.instance.load();
  await ScanStore.instance.load();
  unawaited(InterstitialService.preload());
  AdMobService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final localStorage = LocalStorage();
  final plantProvider = PlantProvider(localStorage);
  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  final iapService = IAPService();
  AdSlot.setPurchased(iapService.value);
  iapService.addListener(() => AdSlot.setPurchased(iapService.value));

  runApp(
    GrowLogApp(
      plantProvider: plantProvider,
      themeProvider: themeProvider,
      localeProvider: localeProvider,
      iapService: iapService,
    ),
  );
}

class GrowLogApp extends StatelessWidget {
  final PlantProvider plantProvider;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  final IAPService iapService;

  const GrowLogApp({
    super.key,
    required this.plantProvider,
    required this.themeProvider,
    required this.localeProvider,
    required this.iapService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.value == ThemeMode.dark ||
            (themeProvider.value == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        _updateSystemUI(isDark);

        return ListenableBuilder(
          listenable: Listenable.merge([plantProvider, localeProvider]),
          builder: (context, _) {
            return MaterialApp(
              // Attached so ErrorHandler can recover to the root route
              // (popUntil isFirst) from a global ErrorWidget.builder,
              // which otherwise has no BuildContext of its own to
              // navigate with. See lib/utils/error_handler.dart.
              navigatorKey: ErrorHandler.navigatorKey,
              title: 'GrowLog',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: localeProvider.value,
              supportedLocales: const [
                Locale('en'),
                Locale('es'),
                Locale('fr'),
                Locale('de'),
                Locale('pt'),
                Locale('ar'),
                Locale('hi'),
                Locale('ja'),
                Locale('ko'),
                Locale('zh'),
                Locale('he'),
              ],
              theme: _lightTheme(),
              darkTheme: _darkTheme(),
              themeMode: themeProvider.value,
              home: AppShell(
                plantProvider: plantProvider,
                themeProvider: themeProvider,
                localeProvider: localeProvider,
                iapService: iapService,
              ),
            );
          },
        );
      },
    );
  }

  void _updateSystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  TextTheme _textTheme(Color ink) {
    return TextTheme(
      displayLarge: AppTypography.display.copyWith(color: ink),
      displayMedium: AppTypography.headline.copyWith(color: ink),
      displaySmall: AppTypography.title1.copyWith(color: ink),
      headlineLarge: AppTypography.headline.copyWith(color: ink),
      headlineMedium: AppTypography.title1.copyWith(color: ink),
      headlineSmall: AppTypography.title1.copyWith(color: ink),
      titleLarge: AppTypography.title1.copyWith(color: ink),
      titleMedium: AppTypography.title2.copyWith(color: ink),
      titleSmall: AppTypography.callout.copyWith(color: ink),
      bodyLarge: AppTypography.body.copyWith(color: ink),
      bodyMedium: AppTypography.callout.copyWith(color: ink),
      bodySmall: AppTypography.footnote.copyWith(color: ink),
      labelLarge: AppTypography.callout.copyWith(color: ink),
      labelMedium: AppTypography.caption.copyWith(color: ink),
      labelSmall: AppTypography.caption.copyWith(color: ink),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: AppTypography.sans,
      textTheme: _textTheme(AppColors.textPrimary),
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.chlorophyll,
        surface: AppColors.bgSecondary,
        onSurface: AppColors.textPrimary,
        outline: AppColors.borderSubtle,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.serif,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        color: AppColors.bgSecondary,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: AppTypography.sans,
      textTheme: _textTheme(AppColors.textPrimaryDark),
      scaffoldBackgroundColor: AppColors.bgPrimaryDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentLight,
        onPrimary: AppColors.bgPrimaryDark,
        secondary: AppColors.chlorophyll,
        surface: AppColors.bgSecondaryDark,
        onSurface: AppColors.textPrimaryDark,
        outline: AppColors.borderSubtleDark,
        error: AppColors.errorDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.serif,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentLight,
          foregroundColor: AppColors.bgPrimaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgTertiaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.borderSubtleDark),
        ),
        color: AppColors.bgSecondaryDark,
      ),
    );
  }
}

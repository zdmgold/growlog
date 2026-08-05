import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/plant_provider.dart';
import 'providers/theme_provider.dart';
import 'services/local_storage.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'services/iap_service.dart';
import 'utils/error_handler.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorHandler.install();

  await NotificationService.initialize();
  AdMobService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final localStorage = LocalStorage();
  final plantProvider = PlantProvider(localStorage);
  final themeProvider = ThemeProvider();
  final iapService = IAPService();

  runApp(
    GrowLogApp(
      plantProvider: plantProvider,
      themeProvider: themeProvider,
      iapService: iapService,
    ),
  );
}

class GrowLogApp extends StatelessWidget {
  final PlantProvider plantProvider;
  final ThemeProvider themeProvider;
  final IAPService iapService;

  const GrowLogApp({
    super.key,
    required this.plantProvider,
    required this.themeProvider,
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
          listenable: plantProvider,
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
              home: HomeScreen(
                plantProvider: plantProvider,
                themeProvider: themeProvider,
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

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentLight,
        surface: AppColors.bgSecondary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        color: AppColors.bgSecondary,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPrimaryDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentLight,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        surface: AppColors.bgSecondaryDark,
        error: AppColors.errorDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentLight,
          foregroundColor: Colors.white,
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
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        color: AppColors.bgSecondaryDark,
      ),
    );
  }
}

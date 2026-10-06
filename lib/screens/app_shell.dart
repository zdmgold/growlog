import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/theme_provider.dart';
import '../services/iap_service.dart';
import '../utils/scan_launcher.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_dock.dart';
import 'care_schedule_screen.dart';
import 'garden_screen.dart';
import 'home_screen.dart';
import 'scans_screen.dart';

/// The app's main frame: four hubs behind a dock, with the banner slot above
/// the dock. Tabs: 0 Home, 1 Garden, 2 Schedule, 3 Scans.
class AppShell extends StatefulWidget {
  final PlantProvider plantProvider;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  final IAPService iapService;

  const AppShell({
    super.key,
    required this.plantProvider,
    required this.themeProvider,
    required this.localeProvider,
    required this.iapService,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(
              plantProvider: widget.plantProvider,
              themeProvider: widget.themeProvider,
              localeProvider: widget.localeProvider,
              iapService: widget.iapService,
              onGoToTab: _go,
            ),
            GardenScreen(plantProvider: widget.plantProvider),
            CareScheduleScreen(
              plantProvider: widget.plantProvider,
              embedded: true,
            ),
            ScansScreen(plantProvider: widget.plantProvider),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdBottomArea(),
            AppDock(
              index: _index,
              onTab: _go,
              onScan: () => ScanLauncher.camera(context, widget.plantProvider),
            ),
          ],
        ),
      ),
    );
  }
}

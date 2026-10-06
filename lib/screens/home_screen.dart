import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/plant_model.dart';
import '../providers/locale_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/theme_provider.dart';
import '../services/admob_service.dart';
import '../services/ai/ai_settings.dart';
import '../services/scan_store.dart';
import '../services/iap_service.dart';
import '../utils/care_due.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/care_today_row.dart';
import '../widgets/recent_scans_row.dart';
import '../widgets/connect_ai_card.dart';
import '../widgets/home_header.dart';
import '../widgets/language_sheet.dart';
import '../widgets/scan_hero_card.dart';
import '../widgets/specimen_card.dart';
import 'add_plant_screen.dart';
import 'ai_setup_screen.dart';
import 'camera_screen.dart';
import 'care_schedule_screen.dart';
import 'paul_chat_screen.dart';
import 'plant_detail_screen.dart';
import 'scan_screen.dart';
import 'scans_screen.dart';
import 'settings_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  final IAPService iapService;

  const HomeScreen({
    super.key,
    required this.plantProvider,
    required this.themeProvider,
    required this.localeProvider,
    required this.iapService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _roomFilter;
  int _selectedIndex = 0;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Plant> _gardenPlants(List<Plant> plants) {
    var list = plants;
    if (_roomFilter != null) {
      list = list.where((p) => p.roomId == _roomFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.species?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  void _push(Widget screen, {bool resetNav = false}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      if (resetNav && mounted) setState(() => _selectedIndex = 0);
    });
  }

  void _openSettings() => _push(
        SettingsScreen(
          plantProvider: widget.plantProvider,
          themeProvider: widget.themeProvider,
          iapService: widget.iapService,
        ),
      );

  void _addPlant() =>
      _push(AddPlantScreen(plantProvider: widget.plantProvider));

  void _openAiSetup() => _push(const AiSetupScreen());

  /// Scanning needs an AI provider. Sends the user to set one up first.
  bool _ensureAi() {
    if (AiSettings.instance.isConfigured) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add your API key to scan plants.')),
    );
    _openAiSetup();
    return false;
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _addPlant();
      return;
    }
    setState(() => _selectedIndex = index);
    if (index == 1) {
      _push(CareScheduleScreen(plantProvider: widget.plantProvider),
          resetNav: true);
    } else if (index == 3) {
      _push(WishlistScreen(plantProvider: widget.plantProvider),
          resetNav: true);
    } else if (index == 4) {
      _push(
        SettingsScreen(
          plantProvider: widget.plantProvider,
          themeProvider: widget.themeProvider,
          iapService: widget.iapService,
        ),
        resetNav: true,
      );
    }
  }

  void _openScan(String imagePath) {
    _push(
      ScanScreen(
        plantProvider: widget.plantProvider,
        imagePath: imagePath,
      ),
    );
  }

  Future<void> _scanWithCamera() async {
    HapticFeedback.mediumImpact();
    if (!_ensureAi()) return;
    final result = await Navigator.push<CameraResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CameraScreen(),
      ),
    );
    if (result == null || !mounted) return;
    _openScan(result.path);
  }

  Future<void> _scanFromGallery() async {
    if (!_ensureAi()) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
    );
    if (picked == null || !mounted) return;
    _openScan(picked.path);
  }

  void _openHistory() =>
      _push(ScansScreen(plantProvider: widget.plantProvider));

  void _openPlant(Plant plant) {
    _push(
      PlantDetailScreen(
        plantProvider: widget.plantProvider,
        plantId: plant.id,
      ),
    );
  }

  void _openSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(
        controller: _searchController,
        onChanged: (v) {
          if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _searchQuery = v);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.plantProvider,
          builder: (context, _) {
            final all = widget.plantProvider.activePlants;
            final rooms = widget.plantProvider.rooms;
            final due = dueCare(all);
            final upcoming = due.isEmpty ? nextUpcoming(all) : null;
            final garden = _gardenPlants(all);

            return RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await widget.plantProvider.reload();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: HomeHeader(
                      themeProvider: widget.themeProvider,
                      dueCount: due.length,
                      plantCount: all.length,
                      onLanguage: () =>
                          showLanguageSheet(context, widget.localeProvider),
                      onSettings: _openSettings,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: ScanHeroCard(
                        hasPlants: all.isNotEmpty,
                        onPrimary: _scanWithCamera,
                        onGallery: _scanFromGallery,
                        onHistory: _openHistory,
                        onPaul: () => _push(
                          PaulChatScreen(plantProvider: widget.plantProvider),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
                      ),
                      child: ConnectAiCard(onTap: _openAiSetup),
                    ),
                  ),
                  if (all.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionTitle(
                        title: "Today's care",
                        trailing: TextButton(
                          onPressed: () => _push(
                            CareScheduleScreen(
                              plantProvider: widget.plantProvider,
                            ),
                          ),
                          child: const Text('See all'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: CareTodayRow(
                        due: due,
                        upcoming: upcoming,
                        plantProvider: widget.plantProvider,
                        onOpenPlant: _openPlant,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: ListenableBuilder(
                      listenable: ScanStore.instance,
                      builder: (context, _) {
                        if (ScanStore.instance.scans.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            _SectionTitle(
                              title: 'Recent scans',
                              trailing: TextButton(
                                onPressed: _openHistory,
                                child: const Text('See all'),
                              ),
                            ),
                            RecentScansRow(
                              onOpen: (scan) => _push(
                                ScanScreen(
                                  plantProvider: widget.plantProvider,
                                  record: scan,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: 'My garden',
                      trailing: all.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Search plants',
                              icon: Icon(PhosphorRegular.magnifyingGlass,
                                  size: 22, color: ink),
                              onPressed: _openSearch,
                            ),
                    ),
                  ),
                  if (all.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyGarden(onAdd: _addPlant),
                    )
                  else ...[
                    if (rooms.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _RoomChips(
                          rooms: rooms.map((r) => (r.id, r.name)).toList(),
                          selected: _roomFilter,
                          onSelect: (id) => setState(() => _roomFilter = id),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: garden.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text(
                                'No plants match this filter.',
                                style: AppTypography.body.copyWith(color: sub),
                              ),
                            )
                          : SizedBox(
                              height: 252,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                itemCount: garden.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: AppSpacing.md),
                                itemBuilder: (context, i) {
                                  final plant = garden[i];
                                  return SizedBox(
                                    width: 176,
                                    child: SpecimenCard(
                                      plant: plant,
                                      plantProvider: widget.plantProvider,
                                      onTap: () => _openPlant(plant),
                                      onLongPress: () {
                                        HapticFeedback.lightImpact();
                                        _showPlantMenu(plant);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.iapService,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.iapService.value) AdMobService.bannerAd(),
              BottomNavBar(
                currentIndex: _selectedIndex,
                onTap: _onNavTap,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPlantMenu(Plant plant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlantMenuSheet(
        plant: plant,
        onDelete: () {
          HapticFeedback.mediumImpact();
          widget.plantProvider.deletePlant(plant.id);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${plant.name} deleted'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => widget.plantProvider.restorePlant(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xl, AppSpacing.md, AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.title1.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RoomChips extends StatelessWidget {
  final List<(String, String)> rooms;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _RoomChips({
    required this.rooms,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
        ),
        children: [
          _chip(context, 'All', selected == null, () => onSelect(null)),
          for (final (id, name) in rooms)
            _chip(context, name, selected == id, () => onSelect(id)),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = active
        ? (isDark ? AppColors.accentLight : AppColors.forest)
        : (isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary);
    final fg = active
        ? (isDark ? AppColors.bgPrimaryDark : Colors.white)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: active,
        label: '$label rooms filter',
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: BorderSide(
              color: active
                  ? Colors.transparent
                  : (isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle),
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.callout.copyWith(
                    color: fg,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyGarden extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGarden({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorFill.plant, size: 30, color: accent),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your garden is empty',
              style: AppTypography.title1.copyWith(color: ink),
            ),
            const SizedBox(height: 4),
            Text(
              'Plants you add appear here as specimen cards.',
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: sub),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(PhosphorBold.plus, size: 18),
              label: const Text('Add a plant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSheet extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchSheet({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search plants...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? AppColors.bgTertiaryDark : AppColors.bgTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantMenuSheet extends StatelessWidget {
  final Plant plant;
  final VoidCallback onDelete;

  const _PlantMenuSheet({
    required this.plant,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text(plant.isDead ? 'Revive' : 'Mark as Dead'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Photos'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Plant?'),
                    content: Text(
                        'This will permanently delete ${plant.name} and all its photos.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: onDelete,
                        child: const Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plant_model.dart';
import '../models/room_model.dart';
import '../providers/plant_provider.dart';
import '../providers/theme_provider.dart';
import '../services/admob_service.dart';
import '../services/iap_service.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/plant_card.dart';
import '../widgets/room_card.dart';
import '../widgets/next_care_badge.dart';
import 'plant_detail_screen.dart';
import 'add_plant_screen.dart';
import 'care_schedule_screen.dart';
import 'rooms_screen.dart';
import 'settings_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  // SURGICAL ADDITION: needed so Settings (File 32) can bind its theme
  // picker to the real ThemeProvider instance created in main.dart,
  // rather than each screen creating its own (which would desync).
  final ThemeProvider themeProvider;
  // SURGICAL ADDITION: needed both to conditionally hide the ad banner
  // below (once Remove Ads is purchased) and to thread through to
  // SettingsScreen for the actual purchase button.
  final IAPService iapService;

  const HomeScreen({
    super.key,
    required this.plantProvider,
    required this.themeProvider,
    required this.iapService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 0;

  // SURGICAL ADDITION: debounce timer for search. Previously every
  // keystroke triggered an immediate setState + full list rebuild.
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Plant> _filteredPlants(List<Plant> plants) {
    if (_searchQuery.isEmpty) return plants;
    final q = _searchQuery.toLowerCase();
    return plants.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.species?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// SURGICAL FIX: previously called `Navigator.push(...)` without
  /// awaiting it, then immediately called `setState(() => _selectedIndex
  /// = 0)` right after — since `push` returns a Future rather than
  /// blocking, that reset ran instantly, before the pushed screen even
  /// finished animating in. The nav bar would flash the destination
  /// icon as selected for a single frame and then snap back to Garden.
  /// Chaining `.then()` on the push's Future defers the reset until the
  /// user has actually navigated back, matching the fix-plan spec
  /// ("Nav index managed via then() callback instead of flash-reset").
  void _onNavTap(int index) {
    // Haptic feedback now fires inside BottomNavBar's _NavItem/
    // _CreateButton (Fix Phase B) before this callback is invoked, so
    // the duplicate call that used to be here has been removed.
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddPlantScreen(plantProvider: widget.plantProvider),
        ),
      );
      return;
    }
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CareScheduleScreen(plantProvider: widget.plantProvider),
        ),
      ).then((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WishlistScreen(plantProvider: widget.plantProvider),
        ),
      ).then((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsScreen(
            plantProvider: widget.plantProvider,
            themeProvider: widget.themeProvider,
            iapService: widget.iapService,
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.plantProvider,
          builder: (context, _) {
            final plants = _filteredPlants(widget.plantProvider.activePlants);
            final overdue = widget.plantProvider.overduePlants;
            final rooms = widget.plantProvider.rooms;

            // SURGICAL ADDITION: pull-to-refresh, per fix-plan feature
            // #10. Wraps the existing CustomScrollView unchanged;
            // RefreshIndicator handles its own gesture/spinner and just
            // needs an async callback.
            return RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await widget.plantProvider.reload();
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GrowLog',
                            style: AppTypography.display.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Semantics(
                            label: 'Search plants',
                            child: IconButton(
                              icon: Icon(
                                Icons.search,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _SearchSheet(
                                    controller: _searchController,
                                    // SURGICAL FIX: debounce search input.
                                    // Previously every keystroke called
                                    // setState directly, rebuilding the
                                    // full filtered grid on every
                                    // character. Now waits 300ms of
                                    // inactivity before filtering.
                                    onChanged: (v) {
                                      if (_debounceTimer?.isActive ?? false) {
                                        _debounceTimer!.cancel();
                                      }
                                      _debounceTimer = Timer(
                                        const Duration(milliseconds: 300),
                                        () {
                                          if (mounted) {
                                            setState(() => _searchQuery = v);
                                          }
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (overdue.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SectionHeader(title: 'Needs Care'),
                    ),
                  if (overdue.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: overdue.length,
                          itemBuilder: (context, index) {
                            final plant = overdue[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.md),
                              child: SizedBox(
                                width: 280,
                                child: PlantCard(
                                  plant: plant,
                                  plantProvider: widget.plantProvider,
                                  onTap: () => _openPlant(plant),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (rooms.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Rooms',
                        action: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomsScreen(
                                plantProvider: widget.plantProvider,
                              ),
                            ),
                          ),
                          child: const Text('See All'),
                        ),
                      ),
                    ),
                  if (rooms.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            final roomPlants =
                                widget.plantProvider.plantsInRoom(room.id);
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.md),
                              child: SizedBox(
                                width: 200,
                                child: RoomCard(
                                  room: room,
                                  plants: roomPlants,
                                  plantProvider: widget.plantProvider,
                                  onTap: () {
                                    // Filter garden by room
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _SectionHeader(title: 'My Garden'),
                  ),
                  if (plants.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyGarden(
                        onAdd: () => _onNavTap(2),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.82,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final plant = plants[index];
                            return PlantCard(
                              plant: plant,
                              plantProvider: widget.plantProvider,
                              onTap: () => _openPlant(plant),
                              onLongPress: () {
                                HapticFeedback.lightImpact();
                                _showPlantMenu(plant);
                              },
                            );
                          },
                          childCount: plants.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // SURGICAL ADDITION: this is the actual placement of the ad
      // banner — AdMobService.bannerAd() existed as a real method but
      // was never called from any screen anywhere in the app, meaning
      // the "ads fund the free app" plan was producing zero revenue
      // regardless of whether the ad SDK itself worked. Wrapped in a
      // ListenableBuilder on iapService so it disappears immediately
      // (no restart needed) the moment Remove Ads is purchased.
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

  void _openPlant(Plant plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantDetailScreen(
          plantProvider: widget.plantProvider,
          plantId: plant.id,
        ),
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
          // SURGICAL ADDITION: haptic on the destructive confirmation
          // (feature #8), and an undo SnackBar (feature #3) instead of
          // deleting silently and irreversibly — pairs with
          // PlantProvider.restorePlant() added in Fix Phase A.
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.title1.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          if (action != null) action!,
        ],
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_florist_outlined,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No plants yet',
            style: AppTypography.title1.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap the + button to add your first plant',
            style: AppTypography.body.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Plant'),
            ),
          ),
        ],
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
                // Toggle dead status
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plant_model.dart';
import '../models/room_model.dart';
import '../providers/plant_provider.dart';
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

  const HomeScreen({super.key, required this.plantProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void dispose() {
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

  void _onNavTap(int index) {
    HapticFeedback.lightImpact();
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
          builder: (_) => CareScheduleScreen(plantProvider: widget.plantProvider),
        ),
      );
      setState(() => _selectedIndex = 0);
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WishlistScreen(plantProvider: widget.plantProvider),
        ),
      );
      setState(() => _selectedIndex = 0);
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsScreen(plantProvider: widget.plantProvider),
        ),
      );
      setState(() => _selectedIndex = 0);
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

            return CustomScrollView(
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
                                  onChanged: (v) => setState(() => _searchQuery = v),
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
                            padding: const EdgeInsets.only(right: AppSpacing.md),
                            child: SizedBox(
                              width: 280,
                              child: PlantCard(
                                plant: plant,
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
                          final roomPlants = widget.plantProvider.plantsInRoom(room.id);
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.md),
                            child: SizedBox(
                              width: 200,
                              child: RoomCard(
                                room: room,
                                plants: roomPlants,
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
                            onTap: () => _openPlant(plant),
                            onLongPress: () => _showPlantMenu(plant),
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
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
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
          widget.plantProvider.deletePlant(plant.id);
          Navigator.pop(context);
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
              title: const Text(plant.isDead ? 'Revive' : 'Mark as Dead'),
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
                    content: Text('This will permanently delete ${plant.name} and all its photos.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: onDelete,
                        child: const Text('Delete', style: TextStyle(color: AppColors.error)),
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

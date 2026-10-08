import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import '../widgets/room_chips.dart';
import '../widgets/specimen_card.dart';
import 'add_plant_screen.dart';
import 'plant_detail_screen.dart';
import 'rooms_screen.dart';
import 'wishlist_screen.dart';

/// Garden hub: all plants, the wishlist and rooms, as tabs.
class GardenScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  const GardenScreen({super.key, required this.plantProvider});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final TextEditingController _search = TextEditingController();
  String? _room;
  String _query = '';

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Plant> _filtered(List<Plant> plants) {
    var list = plants;
    if (_room != null) list = list.where((p) => p.roomId == _room).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.species?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  void _openPlant(Plant p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantDetailScreen(
          plantProvider: widget.plantProvider,
          plantId: p.id,
        ),
      ),
    );
  }

  void _addPlant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlantScreen(plantProvider: widget.plantProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Garden'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgSecondaryDark : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: TabBar(
                controller: _tabs,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  color: isDark ? AppColors.bgTertiaryDark : AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
                  ),
                ),
                labelColor: accent,
                unselectedLabelColor: sub,
                labelStyle: AppTypography.callout.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTypography.callout,
                tabs: const [
                  Tab(text: 'Plants'),
                  Tab(text: 'Wishlist'),
                  Tab(text: 'Rooms'),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) {
          if (_tabs.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _addPlant,
            backgroundColor: accent,
            foregroundColor: isDark ? AppColors.bgPrimaryDark : Colors.white,
            icon: const Icon(PhosphorBold.plus, size: 20),
            label: const Text('Add plant'),
          );
        },
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _plantsTab(isDark),
          WishlistScreen(plantProvider: widget.plantProvider, embedded: true),
          RoomsScreen(
            plantProvider: widget.plantProvider,
            embedded: true,
            onOpenRoom: (id) {
              setState(() => _room = id);
              _tabs.animateTo(0);
            },
          ),
        ],
      ),
    );
  }

  Widget _plantsTab(bool isDark) {
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ListenableBuilder(
      listenable: widget.plantProvider,
      builder: (context, _) {
        final all = widget.plantProvider.activePlants;
        final rooms = widget.plantProvider.rooms;
        final plants = _filtered(all);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md,
              ),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search plants',
                  prefixIcon: Icon(PhosphorRegular.magnifyingGlass, size: 20, color: sub),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(PhosphorRegular.x, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            if (rooms.isNotEmpty && all.isNotEmpty)
              RoomChips(
                rooms: rooms.map((r) => (r.id, r.name)).toList(),
                selected: _room,
                onSelect: (id) => setState(() => _room = id),
              ),
            Expanded(
              child: plants.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorRegular.plant, size: 48, color: sub),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              all.isEmpty ? 'Your garden is empty' : 'No plants match',
                              style: AppTypography.title1.copyWith(color: ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              all.isEmpty
                                  ? 'Scan a plant or add one by hand.'
                                  : 'Try another search or room.',
                              textAlign: TextAlign.center,
                              style: AppTypography.body.copyWith(color: sub),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, 96,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.74,
                      ),
                      itemCount: plants.length,
                      itemBuilder: (context, i) {
                        final p = plants[i];
                        return SpecimenCard(
                          plant: p,
                          plantProvider: widget.plantProvider,
                          onTap: () => _openPlant(p),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

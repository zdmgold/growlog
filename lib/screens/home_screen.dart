import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plant_model.dart';
import '../providers/locale_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/theme_provider.dart';
import '../services/ai/ai_settings.dart';
import '../services/scan_store.dart';
import '../services/iap_service.dart';
import '../utils/care_due.dart';
import '../l10n/l10n_ext.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import '../utils/scan_launcher.dart';
import '../widgets/care_today_row.dart';
import '../widgets/room_chips.dart';
import '../widgets/recent_scans_row.dart';
import '../widgets/connect_ai_card.dart';
import '../widgets/home_header.dart';
import '../widgets/language_sheet.dart';
import '../widgets/scan_hero_card.dart';
import '../widgets/specimen_card.dart';
import 'add_plant_screen.dart';
import 'ai_setup_screen.dart';
import 'paul_chat_screen.dart';
import 'plant_detail_screen.dart';
import 'scan_screen.dart';
import 'scans_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
  final IAPService iapService;

  /// Switches the shell to a hub: 1 Garden, 2 Schedule, 3 Scans.
  final ValueChanged<int> onGoToTab;

  const HomeScreen({
    super.key,
    required this.plantProvider,
    required this.themeProvider,
    required this.localeProvider,
    required this.iapService,
    required this.onGoToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _roomFilter;
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

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
                        onPrimary: () => ScanLauncher.camera(context, widget.plantProvider),
                        onGallery: () => ScanLauncher.gallery(context, widget.plantProvider),
                        onHistory: () => widget.onGoToTab(3),
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
                        title: context.l10n.todaysCare,
                        trailing: TextButton(
                          onPressed: () => widget.onGoToTab(2),
                          child: Text(context.l10n.seeAll),
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
                              title: context.l10n.recentScans,
                              trailing: TextButton(
                                onPressed: () => widget.onGoToTab(3),
                                child: Text(context.l10n.seeAll),
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
                      title: context.l10n.myGarden,
                      trailing: all.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.l10n.searchPlants,
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
                        child: RoomChips(
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
                                context.l10n.noPlantsFilter,
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
    );
  }

  void _showPlantMenu(Plant plant) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PlantMenuSheet(
        plant: plant,
        onOpen: () {
          Navigator.pop(sheetContext);
          _openPlant(plant);
        },
        onToggleDead: () {
          HapticFeedback.lightImpact();
          widget.plantProvider.toggleDead(plant.id);
          Navigator.pop(sheetContext);
        },
        onDelete: () {
          HapticFeedback.mediumImpact();
          widget.plantProvider.deletePlant(plant.id);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.plantDeletedSnack(plant.name)),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: context.l10n.undo,
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
              context.l10n.gardenEmptyTitle,
              style: AppTypography.title1.copyWith(color: ink),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.gardenCardsHint,
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: sub),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(PhosphorBold.plus, size: 18),
              label: Text(context.l10n.addPlant),
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
              hintText: context.l10n.searchPlants,
              prefixIcon: const Icon(PhosphorRegular.magnifyingGlass),
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
  final VoidCallback onOpen;
  final VoidCallback onToggleDead;
  final VoidCallback onDelete;

  const _PlantMenuSheet({
    required this.plant,
    required this.onOpen,
    required this.onToggleDead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final err = isDark ? AppColors.errorDark : AppColors.error;
    final l = context.l10n;

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
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Icon(PhosphorRegular.leaf, color: accent),
              title: Text(l.openPlant),
              onTap: onOpen,
            ),
            ListTile(
              leading: Icon(PhosphorRegular.plant, color: accent),
              title: Text(plant.isDead ? l.revivePlant : l.markAsDead),
              onTap: onToggleDead,
            ),
            ListTile(
              leading: Icon(PhosphorRegular.trash, color: err),
              title: Text(l.delete, style: TextStyle(color: err)),
              onTap: () {
                Navigator.pop(context);
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l.deletePlantTitle),
                    content: Text(l.deletePlantMessage(plant.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(l.cancel),
                      ),
                      TextButton(
                        onPressed: onDelete,
                        child: Text(l.delete, style: TextStyle(color: err)),
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

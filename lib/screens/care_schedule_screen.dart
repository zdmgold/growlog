import 'package:flutter/material.dart';
import 'package:growlog/l10n/app_localizations.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../widgets/next_care_badge.dart';
import 'plant_detail_screen.dart';

/// NEW (Phase 5 cont., File 30). Fresh generation — nothing to recover
/// from the source transcript. Reachable from home_screen.dart's
/// bottom-nav "Schedule" tab (index 1).
class CareScheduleScreen extends StatefulWidget {
  final PlantProvider plantProvider;

  const CareScheduleScreen({super.key, required this.plantProvider});

  @override
  State<CareScheduleScreen> createState() => _CareScheduleScreenState();
}

class _CareScheduleScreenState extends State<CareScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Plant> _upcoming(List<Plant> plants) {
    final now = DateTime.now();
    final withDates = plants.where((p) => _nextDate(p) != null).toList()
      ..sort((a, b) => _nextDate(a)!.compareTo(_nextDate(b)!));
    return withDates.where((p) => _nextDate(p)!.isAfter(now)).toList();
  }

  List<Plant> _overdue(List<Plant> plants) {
    return plants.where((p) => p.isOverdue).toList()
      ..sort((a, b) => _nextDate(a)!.compareTo(_nextDate(b)!));
  }

  DateTime? _nextDate(Plant p) {
    final dates = [
      p.nextWaterDate,
      p.nextFertilizeDate,
      p.nextMistDate,
      p.nextRepotDate,
      p.nextPruneDate,
      p.nextTreatDate,
    ].whereType<DateTime>().toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.plantProvider,
      builder: (context, _) {
        final active = widget.plantProvider.activePlants;
        final upcoming = _upcoming(active);
        final overdue = _overdue(active);

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n?.careScheduleTitle ?? 'Care Schedule',
              style: AppTypography.title1.copyWith(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.accent,
              tabs: [
                Tab(text: l10n?.upcoming ?? 'Upcoming'),
                Tab(text: l10n?.overdueTab ?? 'Overdue'),
                Tab(text: l10n?.all ?? 'All'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _ScheduleList(
                plants: upcoming,
                emptyText: l10n?.noUpcomingCare ?? 'No upcoming care',
                onTap: _openPlant,
              ),
              _ScheduleList(
                plants: overdue,
                emptyText: l10n?.noOverdueCare ?? 'No overdue care',
                onTap: _openPlant,
              ),
              _ScheduleList(
                plants: active,
                emptyText: l10n?.noPlantsYet ?? 'No plants yet',
                onTap: _openPlant,
              ),
            ],
          ),
        );
      },
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
}

class _ScheduleList extends StatelessWidget {
  final List<Plant> plants;
  final String emptyText;
  final void Function(Plant) onTap;

  const _ScheduleList({
    required this.plants,
    required this.emptyText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (plants.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: AppTypography.body.copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Semantics(
            label: '${plant.name} plant card',
            button: true,
            child: Material(
              color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                onTap: () => onTap(plant),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        child: const Icon(Icons.local_florist,
                            color: AppColors.accent),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          plant.name,
                          style: AppTypography.title2.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      NextCareBadge(plant: plant),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

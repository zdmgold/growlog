import 'package:flutter/material.dart';
import '../models/care_log_model.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/care_actions.dart';
import '../utils/care_due.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import '../widgets/care_today_row.dart';
import '../widgets/next_care_badge.dart';
import '../widgets/plant_thumb.dart';
import 'plant_detail_screen.dart';

/// Schedule hub: what is due now, what is coming up, and every plant.
class CareScheduleScreen extends StatefulWidget {
  final PlantProvider plantProvider;
  final bool embedded;

  const CareScheduleScreen({
    super.key,
    required this.plantProvider,
    this.embedded = false,
  });

  @override
  State<CareScheduleScreen> createState() => _CareScheduleScreenState();
}

class _CareScheduleScreenState extends State<CareScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ListenableBuilder(
      listenable: widget.plantProvider,
      builder: (context, _) {
        final active = widget.plantProvider.activePlants;
        final due = dueCare(active);
        final upcoming = upcomingCare(active);
        final sorted = [...active]
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: widget.embedded
                ? null
                : IconButton(
                    tooltip: 'Back',
                    icon: const Icon(PhosphorBold.arrowLeft),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: const Text('Schedule'),
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
                        color: isDark
                            ? AppColors.borderSubtleDark
                            : AppColors.borderSubtle,
                      ),
                    ),
                    labelColor: accent,
                    unselectedLabelColor: sub,
                    labelStyle: AppTypography.callout.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: AppTypography.callout,
                    tabs: [
                      Tab(text: due.isEmpty ? 'Due now' : 'Due now · ${due.length}'),
                      const Tab(text: 'Upcoming'),
                      const Tab(text: 'All'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _DueNow(
                due: due,
                upcoming: upcoming.isEmpty ? null : upcoming.first,
                plantProvider: widget.plantProvider,
                onOpen: _openPlant,
              ),
              _Upcoming(
                items: upcoming,
                plantProvider: widget.plantProvider,
                onOpen: _openPlant,
              ),
              _AllPlants(
                plants: sorted,
                plantProvider: widget.plantProvider,
                onOpen: _openPlant,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Empty({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: accent),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.title1.copyWith(color: ink)),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: sub),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueNow extends StatelessWidget {
  final List<DueCare> due;
  final DueCare? upcoming;
  final PlantProvider plantProvider;
  final void Function(Plant) onOpen;

  const _DueNow({
    required this.due,
    required this.upcoming,
    required this.plantProvider,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (due.isEmpty) {
      final n = upcoming;
      return _Empty(
        icon: PhosphorFill.checkCircle,
        title: 'All caught up',
        text: n == null
            ? 'Add a care schedule to a plant to see tasks here.'
            : 'Next: ${n.type.label} ${n.plant.name} ${n.whenLabel}.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
      ),
      itemCount: due.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final item = due[i];
        return SizedBox(
          height: 138,
          child: CareDueTile(
            item: item,
            plantProvider: plantProvider,
            onOpen: () => onOpen(item.plant),
            onDone: () => markCareDone(context, plantProvider, item),
          ),
        );
      },
    );
  }
}

class _Upcoming extends StatelessWidget {
  final List<DueCare> items;
  final PlantProvider plantProvider;
  final void Function(Plant) onOpen;

  const _Upcoming({
    required this.items,
    required this.plantProvider,
    required this.onOpen,
  });

  String _group(DueCare c) {
    final n = c.daysUntil;
    if (n <= 1) return 'Tomorrow';
    if (n <= 7) return 'This week';
    return 'Later';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _Empty(
        icon: PhosphorRegular.calendarCheck,
        title: 'Nothing coming up',
        text: 'Scheduled care for your plants will show here.',
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final rows = <Widget>[];
    String? current;
    for (final c in items.take(80)) {
      final g = _group(c);
      if (g != current) {
        current = g;
        rows.add(Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
          child: Text(g, style: AppTypography.title1.copyWith(color: ink, fontSize: 19)),
        ));
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: () => onOpen(c.plant),
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: PlantThumb(plant: c.plant, plantProvider: plantProvider),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.plant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title2.copyWith(color: ink),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(careIcon(c.type), size: 14, color: c.type.color),
                            const SizedBox(width: 6),
                            Text(
                              '${c.type.label} · ${c.whenLabel}',
                              style: AppTypography.footnote.copyWith(color: sub),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorBold.caretRight, size: 16, color: sub),
                ],
              ),
            ),
          ),
        ),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl,
      ),
      children: rows,
    );
  }
}

class _AllPlants extends StatelessWidget {
  final List<Plant> plants;
  final PlantProvider plantProvider;
  final void Function(Plant) onOpen;

  const _AllPlants({
    required this.plants,
    required this.plantProvider,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (plants.isEmpty) {
      return const _Empty(
        icon: PhosphorRegular.plant,
        title: 'No plants yet',
        text: 'Scan or add a plant to start its care schedule.',
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl,
      ),
      itemCount: plants.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final p = plants[i];
        return Semantics(
          button: true,
          label: '${p.name}, open plant',
          child: Material(
            color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: () => onOpen(p),
              child: Ink(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: PlantThumb(plant: p, plantProvider: plantProvider),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title2.copyWith(color: ink),
                      ),
                    ),
                    NextCareBadge(plant: p),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

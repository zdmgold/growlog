import 'package:flutter/material.dart';
import '../models/care_log_model.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/care_actions.dart';
import '../utils/care_due.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import 'motion_widgets.dart';
import 'plant_thumb.dart';

IconData careIcon(CareType t) {
  switch (t) {
    case CareType.water:
      return PhosphorFill.drop;
    case CareType.fertilize:
      return PhosphorFill.flask;
    case CareType.mist:
      return PhosphorFill.wind;
    case CareType.repot:
      return PhosphorFill.plant;
    case CareType.prune:
      return PhosphorFill.scissors;
    case CareType.treat:
      return PhosphorFill.firstAidKit;
  }
}

/// Horizontal row of "care due today" tiles. One tap marks the care done,
/// tapping the tile opens the plant.
class CareTodayRow extends StatefulWidget {
  final List<DueCare> due;
  final DueCare? upcoming;
  final PlantProvider plantProvider;
  final void Function(Plant plant) onOpenPlant;

  const CareTodayRow({
    super.key,
    required this.due,
    required this.upcoming,
    required this.plantProvider,
    required this.onOpenPlant,
  });

  @override
  State<CareTodayRow> createState() => _CareTodayRowState();
}

class _CareTodayRowState extends State<CareTodayRow> {
  late final PageController _controller =
      PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markDone(DueCare item) =>
      markCareDone(context, widget.plantProvider, item);

  @override
  Widget build(BuildContext context) {
    if (widget.due.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: _CaughtUpTile(upcoming: widget.upcoming),
      );
    }
    return SizedBox(
      height: 138,
      child: PageView.builder(
        controller: _controller,
        padEnds: false,
        itemCount: widget.due.length,
        itemBuilder: (context, i) {
          final item = widget.due[i];
          return Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? AppSpacing.lg : 0,
              right: i == widget.due.length - 1 ? AppSpacing.lg : AppSpacing.md,
            ),
            child: CareDueTile(
              item: item,
              plantProvider: widget.plantProvider,
              onOpen: () => widget.onOpenPlant(item.plant),
              onDone: () => _markDone(item),
            ),
          );
        },
      ),
    );
  }
}

class CareDueTile extends StatelessWidget {
  final DueCare item;
  final PlantProvider plantProvider;
  final VoidCallback onOpen;
  final VoidCallback onDone;

  const CareDueTile({
    required this.item,
    required this.plantProvider,
    required this.onOpen,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final tint = item.type.color;
    final statusColor = item.isOverdue
        ? (isDark ? AppColors.errorDark : AppColors.attention)
        : (isDark ? AppColors.warningDark : AppColors.watchText);

    return Material(
      color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tint.withOpacity(isDark ? 0.16 : 0.10), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: PlantThumb(
                    plant: item.plant,
                    plantProvider: plantProvider,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(careIcon(item.type), size: 16, color: tint),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${item.type.label} · ${item.statusLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.plant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title1.copyWith(color: ink, fontSize: 19),
                    ),
                    if (item.plant.species != null &&
                        item.plant.species!.trim().isNotEmpty)
                      Text(
                        item.plant.species!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.latin.copyWith(color: sub),
                      ),
                    if (item.others > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${item.others} more',
                          style: AppTypography.caption.copyWith(color: sub),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DoneCheckButton(
                type: item.type,
                semanticLabel: 'Mark ${item.type.label} done for ${item.plant.name}',
                background: isDark ? AppColors.accentLight : AppColors.accent,
                foreground: isDark ? AppColors.bgPrimaryDark : Colors.white,
                onDone: onDone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaughtUpTile extends StatelessWidget {
  final DueCare? upcoming;
  const _CaughtUpTile({required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final next = upcoming;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondaryDark : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorFill.checkCircle, size: 28, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next != null ? 'All caught up' : 'No care scheduled yet',
                  style: AppTypography.title1.copyWith(color: ink, fontSize: 19),
                ),
                const SizedBox(height: 2),
                Text(
                  next != null
                      ? 'Next: ${next.type.label} ${next.plant.name} ${next.whenLabel}'
                      : 'Open a plant and set a watering schedule to see tasks here.',
                  style: AppTypography.footnote.copyWith(color: sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

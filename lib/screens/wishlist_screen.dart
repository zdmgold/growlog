import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:growlog/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/phosphor_icons.dart';

/// Plants you want. "Move to garden" turns a wish into a plant.
class WishlistScreen extends StatelessWidget {
  final PlantProvider plantProvider;
  final bool embedded;

  const WishlistScreen({
    super.key,
    required this.plantProvider,
    this.embedded = false,
  });

  void _showAddSheet(BuildContext context) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Add to wishlist',
                  style: AppTypography.title1.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n?.plantNameLabel ?? 'Plant name *',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      HapticFeedback.mediumImpact();
                      final now = DateTime.now();
                      plantProvider.addPlant(
                        Plant(
                          id: const Uuid().v4(),
                          name: name,
                          acquiredDate: now,
                          createdAt: now,
                          isWishlist: true,
                        ),
                      );
                      Navigator.pop(sheetContext);
                    },
                    child: Text(l10n?.save ?? 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final sub = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: plantProvider,
      builder: (context, _) {
        final wishlist = plantProvider.wishlist;

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
          appBar: embedded
              ? null
              : AppBar(
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    tooltip: 'Back',
                    icon: Icon(PhosphorBold.arrowLeft, color: ink),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(l10n?.wishlistTitle ?? 'Wishlist'),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSheet(context),
            backgroundColor: accent,
            foregroundColor: isDark ? AppColors.bgPrimaryDark : Colors.white,
            icon: const Icon(PhosphorBold.plus, size: 20),
            label: const Text('Add wish'),
          ),
          body: wishlist.isEmpty
              ? Center(
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
                          child: Icon(PhosphorFill.heart, size: 30, color: accent),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n?.noWishlistItems ?? 'No wishlist items',
                          style: AppTypography.title1.copyWith(color: ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep a list of plants you would like to grow.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(color: sub),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 112,
                  ),
                  itemCount: wishlist.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final plant = wishlist[index];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.bgSecondaryDark
                            : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderSubtleDark
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(PhosphorFill.heart, size: 22, color: accent),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plant.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.title1.copyWith(
                                    color: ink,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Wished ${DateFormatter.relative(plant.createdAt).toLowerCase()}',
                                  style: AppTypography.caption.copyWith(color: sub),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              plantProvider.toggleWishlist(plant.id);
                            },
                            child: Text(l10n?.moveToGarden ?? 'Move to Garden'),
                          ),
                          IconButton(
                            tooltip: 'Remove ${plant.name}',
                            icon: Icon(PhosphorRegular.trash, size: 20, color: sub),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              plantProvider.deletePlant(plant.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${plant.name} removed'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () => plantProvider.restorePlant(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

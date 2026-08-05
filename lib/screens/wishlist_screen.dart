import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';

/// NEW (Phase 5 cont., File 33). Fresh generation — nothing to recover
/// from the source transcript. Reachable from home_screen.dart's
/// bottom-nav "Wishlist" tab (index 3).
///
/// Uses `plantProvider.toggleWishlist()` (verified real method on
/// PlantProvider) to move an item from wishlist to garden.
class WishlistScreen extends StatelessWidget {
  final PlantProvider plantProvider;

  const WishlistScreen({super.key, required this.plantProvider});

  void _showAddSheet(BuildContext context) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
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
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n?.plantNameLabel ?? 'Plant name *',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.bgTertiaryDark
                        : AppColors.bgTertiary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide.none,
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: Text(
                      l10n?.save ?? 'Save',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
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
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: plantProvider,
      builder: (context, _) {
        final wishlist = plantProvider.wishlist;

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
              l10n?.wishlistTitle ?? 'Wishlist',
              style: AppTypography.title1.copyWith(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddSheet(context),
              ),
            ],
          ),
          body: wishlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n?.noWishlistItems ?? 'No wishlist items',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: wishlist.length,
                  itemBuilder: (context, index) {
                    final plant = wishlist[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Material(
                        color: isDark
                            ? AppColors.bgSecondaryDark
                            : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    AppColors.accent.withOpacity(0.1),
                                child: const Icon(Icons.favorite,
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
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  plantProvider.toggleWishlist(plant.id);
                                },
                                child:
                                    Text(l10n?.moveToGarden ?? 'Move to Garden'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

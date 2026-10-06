import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:growlog/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../widgets/room_card.dart';

/// NEW (Phase 5 cont., File 31). Fresh generation — nothing to recover
/// from the source transcript. Reachable from home_screen.dart's
/// Rooms section "See All" button.
class RoomsScreen extends StatelessWidget {
  final PlantProvider plantProvider;

  final bool embedded;

  const RoomsScreen({
    super.key,
    required this.plantProvider,
    this.embedded = false,
  });

  void _showAddRoomSheet(BuildContext context, {Room? existing}) {
    final controller = TextEditingController(text: existing?.name ?? '');
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
                    hintText: l10n?.roomNameLabel ?? 'Room name',
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
                      if (existing != null) {
                        plantProvider.updateRoom(
                          Room(
                            id: existing.id,
                            name: name,
                            icon: existing.icon,
                            sortOrder: existing.sortOrder,
                          ),
                        );
                      } else {
                        plantProvider.addRoom(
                          Room(
                            id: const Uuid().v4(),
                            name: name,
                            sortOrder: plantProvider.rooms.length,
                          ),
                        );
                      }
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

  void _confirmDelete(BuildContext context, Room room) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.deleteRoomTitle ?? 'Delete Room?'),
        content: Text(l10n?.deletePlantSimpleMessage ?? 'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              plantProvider.deleteRoom(room.id);
              Navigator.pop(dialogContext);
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
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
        final rooms = plantProvider.rooms;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimary,
          appBar: embedded ? null : AppBar(
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
              l10n?.roomsTitle ?? 'Rooms',
              style: AppTypography.title1.copyWith(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddRoomSheet(context),
              ),
            ],
          ),
          body: rooms.isEmpty
              ? Center(
                  child: Text(
                    l10n?.roomsTitle ?? 'Rooms',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textTertiary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final roomPlants = plantProvider.plantsInRoom(room.id);
                    void openOptions() => showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => SafeArea(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.bgSecondaryDark
                                : AppColors.bgSecondary,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadii.xl)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: Text(l10n?.edit ?? 'Edit'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showAddRoomSheet(context, existing: room);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete,
                                    color: AppColors.error),
                                title: Text(
                                  l10n?.delete ?? 'Delete',
                                  style: const TextStyle(
                                      color: AppColors.error),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _confirmDelete(context, room);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    // FIX: a bare GestureDetector.onLongPress is
                    // completely undiscoverable to screen reader users
                    // — there's no way to know the gesture exists.
                    // Semantics.onLongPress exposes the same action as
                    // an announced custom action instead.
                    return Semantics(
                      onLongPress: openOptions,
                      child: GestureDetector(
                        onLongPress: openOptions,
                        child: RoomCard(
                          room: room,
                          plants: roomPlants,
                          plantProvider: plantProvider,
                          onTap: () {},
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:growlog/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import '../providers/plant_provider.dart';
import '../utils/constants.dart';
import '../utils/phosphor_icons.dart';
import '../widgets/room_card.dart';

/// NEW (Phase 5 cont., File 31). Fresh generation — nothing to recover
/// from the source transcript. Reachable from home_screen.dart's
/// Rooms section "See All" button.
class RoomsScreen extends StatelessWidget {
  final PlantProvider plantProvider;

  final bool embedded;

  /// Called when a room card is tapped, with the room id.
  final ValueChanged<String>? onOpenRoom;

  const RoomsScreen({
    super.key,
    required this.plantProvider,
    this.embedded = false,
    this.onOpenRoom,
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    existing == null ? 'New room' : 'Edit room',
                    style: AppTypography.title1.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n?.roomNameLabel ?? 'Room name',
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
          appBar: embedded
              ? null
              : AppBar(
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    tooltip: 'Back',
                    icon: Icon(
                      PhosphorBold.arrowLeft,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(l10n?.roomsTitle ?? 'Rooms'),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddRoomSheet(context),
            backgroundColor: isDark ? AppColors.accentLight : AppColors.accent,
            foregroundColor: isDark ? AppColors.bgPrimaryDark : Colors.white,
            icon: const Icon(PhosphorBold.plus, size: 20),
            label: const Text('Add room'),
          ),
          body: rooms.isEmpty
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
                            color: (isDark ? AppColors.accentLight : AppColors.accent)
                                .withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            PhosphorFill.house,
                            size: 30,
                            color: isDark ? AppColors.accentLight : AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No rooms yet',
                          style: AppTypography.title1.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Group plants by where they live, like Kitchen or Balcony.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 112,
                  ),
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
                                leading: const Icon(PhosphorRegular.pencilSimple),
                                title: Text(l10n?.edit ?? 'Edit'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showAddRoomSheet(context, existing: room);
                                },
                              ),
                              ListTile(
                                leading: const Icon(PhosphorRegular.trash,
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
                          onTap: () => onOpenRoom?.call(room.id),
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

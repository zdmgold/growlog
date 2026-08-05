import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum CareType {
  water,
  fertilize,
  mist,
  repot,
  prune,
  treat,
}

extension CareTypeExtension on CareType {
  String get label {
    switch (this) {
      case CareType.water:
        return 'Water';
      case CareType.fertilize:
        return 'Fertilize';
      case CareType.mist:
        return 'Mist';
      case CareType.repot:
        return 'Repot';
      case CareType.prune:
        return 'Prune';
      case CareType.treat:
        return 'Treat';
    }
  }

  String get iconEmoji {
    switch (this) {
      case CareType.water:
        return '💧';
      case CareType.fertilize:
        return '🧪';
      case CareType.mist:
        return '☁️';
      case CareType.repot:
        return '🪴';
      case CareType.prune:
        return '✂️';
      case CareType.treat:
        return '🩹';
    }
  }

  // FIX: care_calendar.dart calls `l.type.color` but this getter never
  // existed in the original source — a genuine compile error in the
  // transcript itself, not something introduced by any edit here.
  // Colors match constants.dart's AppColors.water/fertilize/mist/
  // repot/prune/treat exactly, which are already used for this same
  // purpose in care_quick_actions.dart's _ActionConfig.
  Color get color {
    switch (this) {
      case CareType.water:
        return AppColors.water;
      case CareType.fertilize:
        return AppColors.fertilize;
      case CareType.mist:
        return AppColors.mist;
      case CareType.repot:
        return AppColors.repot;
      case CareType.prune:
        return AppColors.prune;
      case CareType.treat:
        return AppColors.treat;
    }
  }
}

class CareLog {
  final String id;
  final String plantId;
  final CareType type;
  final DateTime date;
  final String? notes;

  const CareLog({
    required this.id,
    required this.plantId,
    required this.type,
    required this.date,
    this.notes,
  });

  CareLog copyWith({
    String? id,
    String? plantId,
    CareType? type,
    DateTime? date,
    String? notes,
  }) {
    return CareLog(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plantId': plantId,
        'type': type.name,
        'date': date.toIso8601String(),
        'notes': notes,
      };

  factory CareLog.fromJson(Map<String, dynamic> json) => CareLog(
        id: json['id'] as String,
        plantId: json['plantId'] as String,
        type: CareType.values.byName(json['type'] as String),
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

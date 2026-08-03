class Room {
  final String id;
  final String name;
  final String? icon;
  final int sortOrder;

  const Room({
    required this.id,
    required this.name,
    this.icon,
    this.sortOrder = 0,
  });

  Room copyWith({
    String? id,
    String? name,
    String? icon,
    int? sortOrder,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'sortOrder': sortOrder,
  };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String?,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Room &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

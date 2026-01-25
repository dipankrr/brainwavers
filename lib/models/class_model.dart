class Class {
  final String id;
  final String name;
  final int orderIndex;
  final DateTime createdAt;

  Class({
    required this.id,
    required this.name,
    required this.orderIndex,
    required this.createdAt,
  });

  factory Class.fromMap(Map<String, dynamic> map) {
    return Class(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      orderIndex: map['order_index'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
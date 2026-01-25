class Section {
  final String id;
  final String classId;
  final String name;
  final int orderIndex;
  final DateTime createdAt;

  Section({
    required this.id,
    required this.classId,
    required this.name,
    required this.orderIndex,
    required this.createdAt,
  });

  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'] ?? '',
      classId: map['class_id'] ?? '',
      name: map['name'] ?? '',
      orderIndex: map['order_index'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
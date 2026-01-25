class Subject {
  final String id;
  final String classId;
  final String name;
  final int totalMarks;
  final int passMarks;
  final int orderIndex;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.classId,
    required this.name,
    required this.totalMarks,
    required this.passMarks,
    required this.orderIndex,
    required this.createdAt,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] ?? '',
      classId: map['class_id'] ?? '',
      name: map['name'] ?? '',
      totalMarks: map['total_marks'] ?? 100,
      passMarks: map['pass_marks'] ?? 40,
      orderIndex: map['order_index'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'total_marks': totalMarks,
      'pass_marks': passMarks,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Subject copyWith({
    String? id,
    String? classId,
    String? name,
    int? totalMarks,
    int? passMarks,
    int? orderIndex,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      totalMarks: totalMarks ?? this.totalMarks,
      passMarks: passMarks ?? this.passMarks,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
class AcademicYear {
  final String id;
  final String year;
  final bool isActive;
  final DateTime createdAt;

  AcademicYear({
    required this.id,
    required this.year,
    required this.isActive,
    required this.createdAt,
  });

  factory AcademicYear.fromMap(Map<String, dynamic> map) {
    return AcademicYear(
      id: map['id'] ?? '',
      year: map['year'] ?? '',
      isActive: map['is_active'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ✅ Add this method
  AcademicYear copyWith({
    String? id,
    String? year,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      year: year ?? this.year,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

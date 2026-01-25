

class Mark {
  final String id;
  final String studentId;
  final String subjectId;
  final String franchiseId;
  final String academicYearId;
  final int term;
  final int marksObtained;
  final bool isAbsent;
  final DateTime createdAt;

  Mark({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.franchiseId,
    required this.academicYearId,
    required this.term,
    required this.marksObtained,
    required this.isAbsent,
    required this.createdAt,
  });

  factory Mark.fromMap(Map<String, dynamic> map) {
    return Mark(
      id: map['id'] ?? '',
      studentId: map['student_id'] ?? '',
      subjectId: map['subject_id'] ?? '',
      franchiseId: map['franchise_id'] ?? '',
      academicYearId: map['academic_year_id'] ?? '',
      term: map['term'] ?? 1,
      marksObtained: map['marks_obtained'] ?? 0,
      isAbsent: map['is_absent'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'subject_id': subjectId,
      'franchise_id': franchiseId,
      'academic_year_id': academicYearId,
      'term': term,
      'marks_obtained': marksObtained,
      'is_absent': isAbsent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Mark copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? franchiseId,
    String? academicYearId,
    int? term,
    int? marksObtained,
    bool? isAbsent,
    DateTime? createdAt,
  }) {
    return Mark(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      franchiseId: franchiseId ?? this.franchiseId,
      academicYearId: academicYearId ?? this.academicYearId,
      term: term ?? this.term,
      marksObtained: marksObtained ?? this.marksObtained,
      isAbsent: isAbsent ?? this.isAbsent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
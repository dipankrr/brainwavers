import 'package:brainwavers/models/student_model.dart';
import 'package:brainwavers/models/subject_model.dart';

class StudentResult {
  final Student student;
  final Map<String, SubjectResult> subjectResults; // subjectId -> SubjectResult
  final TermResult termResult;
  final TermResult? yearlyResult; // Only for term 3

  StudentResult({
    required this.student,
    required this.subjectResults,
    required this.termResult,
    this.yearlyResult,
  });
}

class SubjectResult {
  final Subject subject;
  final int? term1Marks;
  final int? term2Marks;
  final int? term3Marks;
  final int totalMarks; // For current term
  final int? yearlyTotal; // term1+term2+term3 (only for term 3)
  final bool isAbsent;
  final String grade;
  final double percentage;

  SubjectResult({
    required this.subject,
    this.term1Marks,
    this.term2Marks,
    this.term3Marks,
    required this.totalMarks,
    this.yearlyTotal,
    required this.isAbsent,
    required this.grade,
    required this.percentage,
  });
}

class TermResult {
  final int totalMarksObtained;
  final int totalMaxMarks;
  final double percentage;
  final String grade;

  TermResult({
    required this.totalMarksObtained,
    required this.totalMaxMarks,
    required this.percentage,
    required this.grade,
  });
}
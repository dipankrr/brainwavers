import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../models/mark_model.dart';
import '../models/result_model.dart';
import '../utils/grade_calculator.dart';
import '../services/supabase_service.dart';

class ResultsProvider with ChangeNotifier {
  List<StudentResult> _results = [];
  bool _isLoading = false;
  String? _error;

  List<StudentResult> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch results based on filters
  Future<void> fetchResults({
    required String academicYearId,
    required String classId,
    String? sectionId,
    required int term,
  }) async {
    _setLoading(true);
    try {
      // 1. Get students with filters
      final students = await _getFilteredStudents(
        academicYearId: academicYearId,
        classId: classId,
        sectionId: sectionId,
      );

      // 2. Get subjects for the class
      final subjects = await _getSubjectsForClass(classId);

      // 3. Get marks for the selected term (and all terms if term 3)
      final marks = await _getMarksForResults(
        academicYearId: academicYearId,
        classId: classId,
        sectionId: sectionId,
        term:  term == 4 ? 3 : term,
        students: students,
      );

      // 4. Calculate results
      _results = _calculateResults(
        students: students,
        subjects: subjects,
        marks: marks,
        term:  term == 4 ? 3 : term,
        academicYearId: academicYearId,
      );

      _error = null;
    } catch (e) {
      _error = 'Failed to fetch results: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get filtered students
  Future<List<Student>> _getFilteredStudents({
    required String academicYearId,
    required String classId,
    String? sectionId,
  }) async {
    try {
      final allStudents = await SupabaseService.getStudents();
      return allStudents.where((student) {
        if (student.admissionYearId != academicYearId) return false;
        if (student.classId != classId) return false;
        return true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  // Get subjects for class
  Future<List<Subject>> _getSubjectsForClass(String classId) async {
    try {
      final allSubjects = await SupabaseService.getSubjects();
      return allSubjects.where((subject) => subject.classId == classId).toList();
    } catch (e) {
      throw Exception('Failed to get subjects: $e');
    }
  }

  // Get marks for results calculation
  Future<List<Mark>> _getMarksForResults({
    required String academicYearId,
    required String classId,
    String? sectionId,
    required int term,
    required List<Student> students,
  }) async {
    try {
      final allMarks = await SupabaseService.getMarks();

      // Get student IDs
      final studentIds = students.map((s) => s.id).toSet();

      // Filter marks
      return allMarks.where((mark) {
        if (mark.academicYearId != academicYearId) return false;
        if (!studentIds.contains(mark.studentId)) return false;

        // For term 3, we need all terms (1, 2, 3)
        if (term == 3) {
          return mark.term == 1 || mark.term == 2 || mark.term == 3;
        }

        // For term 1 or 2, only get the selected term
        return mark.term == term;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get marks: $e');
    }
  }

  // Calculate results
  List<StudentResult> _calculateResults({
    required List<Student> students,
    required List<Subject> subjects,
    required List<Mark> marks,
    required int term,
    required String academicYearId,
  }) {
    final List<StudentResult> results = [];

    for (final student in students) {
      // Calculate subject-wise results
      final Map<String, SubjectResult> subjectResults = {};

      for (final subject in subjects) {
        final subjectResult = _calculateSubjectResult(
          student: student,
          subject: subject,
          marks: marks,
          term: term,
          academicYearId: academicYearId,
        );
        subjectResults[subject.id] = subjectResult;
      }

      // Calculate term result
      final termResult = _calculateTermResult(subjectResults);

      // Calculate yearly result if term 3
      TermResult? yearlyResult;
      if (term == 3) {
        yearlyResult = _calculateYearlyResult(
          student: student,
          subjects: subjects,
          marks: marks,
          academicYearId: academicYearId,
        );
      }

      results.add(StudentResult(
        student: student,
        subjectResults: subjectResults,
        termResult: termResult,
        yearlyResult: yearlyResult,
      ));
    }

    // Sort by total percentage (descending)
    results.sort((a, b) => b.termResult.percentage.compareTo(a.termResult.percentage));

    return results;
  }

  // Calculate result for a single subject
  SubjectResult _calculateSubjectResult({
    required Student student,
    required Subject subject,
    required List<Mark> marks,
    required int term,
    required String academicYearId,
  }) {
    // Get marks for this student-subject combination
    final termMarks = marks.where((mark) =>
    mark.studentId == student.id &&
        mark.subjectId == subject.id &&
        mark.term == term
    ).firstOrNull;

    // Get marks for term 1 and 2 if term 3
    Mark? term1Mark;
    Mark? term2Mark;
    if (term == 3) {
      term1Mark = marks.where((mark) =>
      mark.studentId == student.id &&
          mark.subjectId == subject.id &&
          mark.term == 1
      ).firstOrNull;

      term2Mark = marks.where((mark) =>
      mark.studentId == student.id &&
          mark.subjectId == subject.id &&
          mark.term == 2
      ).firstOrNull;
    }

    // Calculate values
    final isAbsent = termMarks?.isAbsent ?? true;
    final marksObtained = isAbsent ? 0 : (termMarks?.marksObtained ?? 0);
    final term1Marks = term1Mark?.isAbsent == true ? 0 : (term1Mark?.marksObtained ?? 0);
    final term2Marks = term2Mark?.isAbsent == true ? 0 : (term2Mark?.marksObtained ?? 0);
    final yearlyTotal = term == 3 ? (term1Marks + term2Marks + marksObtained) : null;

    final percentage = GradeCalculator.calculatePercentage(marksObtained, subject.totalMarks);
    final grade = GradeCalculator.calculateGrade(percentage);

    return SubjectResult(
      subject: subject,
      term1Marks: term == 3 ? term1Marks : null,
      term2Marks: term == 3 ? term2Marks : null,
      term3Marks: term == 3 ? marksObtained : null,
      totalMarks: marksObtained,
      yearlyTotal: yearlyTotal,
      isAbsent: isAbsent,
      grade: grade,
      percentage: percentage,
    );
  }

  // Calculate term result (total for all subjects)
  TermResult _calculateTermResult(Map<String, SubjectResult> subjectResults) {
    int totalMarksObtained = 0;
    int totalMaxMarks = 0;

    for (final subjectResult in subjectResults.values) {
      if (!subjectResult.isAbsent) {
        totalMarksObtained += subjectResult.totalMarks;
      }
      //totalMaxMarks += subjectResult.subject.totalMarks;
    }

    final percentage = GradeCalculator.calculatePercentage(totalMarksObtained, totalMaxMarks);
    final grade = GradeCalculator.calculateGrade(percentage);

    return TermResult(
      totalMarksObtained: totalMarksObtained,
      totalMaxMarks: totalMaxMarks,
      percentage: percentage,
      grade: grade,
    );
  }

  // Calculate yearly result (only for term 3)
  TermResult _calculateYearlyResult({
    required Student student,
    required List<Subject> subjects,
    required List<Mark> marks,
    required String academicYearId,
  }) {
    int totalYearlyMarks = 0;
    int totalMaxMarks = 0;

    for (final subject in subjects) {
      // Get marks for all 3 terms
      final term1Mark = marks.where((mark) =>
      mark.studentId == student.id &&
          mark.subjectId == subject.id &&
          mark.term == 1
      ).firstOrNull;

      final term2Mark = marks.where((mark) =>
      mark.studentId == student.id &&
          mark.subjectId == subject.id &&
          mark.term == 2
      ).firstOrNull;

      final term3Mark = marks.where((mark) =>
      mark.studentId == student.id &&
          mark.subjectId == subject.id &&
          mark.term == 3
      ).firstOrNull;

      // Calculate yearly marks for this subject
      final term1Marks = term1Mark?.isAbsent == true ? 0 : (term1Mark?.marksObtained ?? 0);
      final term2Marks = term2Mark?.isAbsent == true ? 0 : (term2Mark?.marksObtained ?? 0);
      final term3Marks = term3Mark?.isAbsent == true ? 0 : (term3Mark?.marksObtained ?? 0);

      totalYearlyMarks += (term1Marks + term2Marks + term3Marks);
      totalMaxMarks += (subject.totalMarks * 3); // Each term has same max marks
    }

    final percentage = GradeCalculator.calculatePercentage(totalYearlyMarks, totalMaxMarks);
    final grade = GradeCalculator.calculateGrade(percentage);

    return TermResult(
      totalMarksObtained: totalYearlyMarks,
      totalMaxMarks: totalMaxMarks,
      percentage: percentage,
      grade: grade,
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
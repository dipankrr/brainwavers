import 'package:flutter/foundation.dart';
import '../models/mark_model.dart';
import '../services/supabase_service.dart';



class MarksProvider with ChangeNotifier {
  List<Mark> _marks = [];
  bool _isLoading = false;
  String? _error;

  List<Mark> get marks => _marks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const List<int> terms = [1, 2, 3];

  // Load all marks
  Future<void> loadMarks() async {
    _setLoading(true);
    try {
      _marks = await SupabaseService.getMarks();
      _error = null;
    } catch (e) {
      _error = 'Failed to load marks: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Save mark with proper error handling
  Future<void> saveMark(Mark mark) async {
    _setLoading(true);
    try {
      final savedMark = await SupabaseService.upsertMark(mark);

      // Update local state
      final index = _marks.indexWhere((m) =>
      m.studentId == mark.studentId &&
          m.subjectId == mark.subjectId &&
          m.academicYearId == mark.academicYearId &&
          m.term == mark.term
      );

      if (index != -1) {
        _marks[index] = savedMark;
      } else {
        _marks.add(savedMark);
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save mark: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get marks for specific student
  Future<List<Mark>> getStudentMarks({
    required String studentId,
    required String academicYearId,
    required int term,
  }) async {
    try {
      return await SupabaseService.getStudentMarks(
        studentId: studentId,
        academicYearId: academicYearId,
        term: term,
      );
    } catch (e) {
      throw Exception('Failed to get student marks: $e');
    }
  }

  // Get mark for specific student and subject
  Mark? getMarkForStudentSubject({
    required String studentId,
    required String subjectId,
    required String academicYearId,
    required int term,
  }) {
    try {
      return _marks.firstWhere(
            (mark) =>
        mark.studentId == studentId &&
            mark.subjectId == subjectId &&
            mark.academicYearId == academicYearId &&
            mark.term == term,
      );
    } catch (e) {
      return null;
    }
  }

  // Add this method to MarksProvider class
  Future<void> loadMarksForFilters({
    required String academicYearId,
    required String classId,
    String? sectionId,
    required int term,
  }) async {
    _setLoading(true);
    try {
      // Get all marks first
      await loadMarks();

      // Then we'll filter locally (since we don't have complex filtered query)
      // In a real scenario, you'd want a proper filtered Supabase query
      _error = null;
    } catch (e) {
      _error = 'Failed to load marks: $e';
    } finally {
      _setLoading(false);
    }
  }

// Add a method to get marks for specific filters
  List<Mark> getMarksForFilters({
    required String academicYearId,
    required String classId,
    String? sectionId,
    required int term,
  }) {
    return _marks.where((mark) =>
    mark.academicYearId == academicYearId &&
        mark.term == term
    ).toList();
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


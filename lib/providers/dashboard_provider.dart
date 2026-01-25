import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class DashboardProvider with ChangeNotifier {
  // Stats data
  int _totalStudents = 0;
  int _totalClasses = 0;
  int _totalSubjects = 0;
  int _totalAcademicYears = 0;
  int _totalMarksEntries = 0;
  int _totalSections = 0;

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  int get totalStudents => _totalStudents;
  int get totalClasses => _totalClasses;
  int get totalSubjects => _totalSubjects;
  int get totalAcademicYears => _totalAcademicYears;
  int get totalMarksEntries => _totalMarksEntries;
  int get totalSections => _totalSections;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all dashboard stats
  Future<void> loadDashboardStats() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadStudentsCount(),
        _loadClassesCount(),
        _loadSubjectsCount(),
        _loadAcademicYearsCount(),
        _loadMarksCount(),
        _loadSectionsCount(),
      ]);
      _error = null;
    } catch (e) {
      _error = 'Failed to load dashboard stats: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Load students count
  Future<void> _loadStudentsCount() async {
    try {
      final students = await SupabaseService.getStudents();
      _totalStudents = students.length;
    } catch (e) {
      throw Exception('Failed to load students count: $e');
    }
  }

  // Load classes count
  Future<void> _loadClassesCount() async {
    try {
      final classes = await SupabaseService.getClasses();
      _totalClasses = classes.length;
    } catch (e) {
      throw Exception('Failed to load classes count: $e');
    }
  }

  // Load subjects count
  Future<void> _loadSubjectsCount() async {
    try {
      final subjects = await SupabaseService.getSubjects();
      _totalSubjects = subjects.length;
    } catch (e) {
      throw Exception('Failed to load subjects count: $e');
    }
  }

  // Load academic years count
  Future<void> _loadAcademicYearsCount() async {
    try {
      final academicYears = await SupabaseService.getAcademicYears();
      _totalAcademicYears = academicYears.length;
    } catch (e) {
      throw Exception('Failed to load academic years count: $e');
    }
  }

  // Load marks count
  Future<void> _loadMarksCount() async {
    try {
      final marks = await SupabaseService.getMarks();
      _totalMarksEntries = marks.length;
    } catch (e) {
      throw Exception('Failed to load marks count: $e');
    }
  }

  // Load sections count
  Future<void> _loadSectionsCount() async {
    try {
      final sections = await SupabaseService.getSections();
      _totalSections = sections.length;
    } catch (e) {
      throw Exception('Failed to load sections count: $e');
    }
  }

  // Refresh all stats
  Future<void> refreshStats() async {
    await loadDashboardStats();
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
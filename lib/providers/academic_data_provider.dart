import 'package:flutter/foundation.dart';
import '../models/academic_year_model.dart';
import '../models/class_model.dart';
import '../models/franchise_model.dart';
import '../models/section_model.dart';
//import '../models/subject_model.dart';
import '../models/subject_model.dart';
import '../services/supabase_service.dart';

class AcademicDataProvider with ChangeNotifier {
  List<AcademicYear> _academicYears = [];
  List<Class> _classes = [];
  List<Section> _sections = [];
  List<Subject> _subjects = [];
  List<Franchise> _franchises = [];

  bool _isLoading = false;
  String? _error;

  List<AcademicYear> get academicYears => _academicYears;
  List<Class> get classes => _classes;
  List<Section> get sections => _sections;
  List<Subject> get subjects => _subjects;
  List<Franchise> get franchises => _franchises;
  bool get isLoading => _isLoading;
  String? get error => _error;


  Future<void> _loadSubjects() async {
    try {
      _subjects = await SupabaseService.getSubjects();
      print(_subjects);
    } catch (e) {
      _error = 'Failed to load subjects: $e';
    }
  }

  // Load all academic data
  Future<void> loadAcademicData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadAcademicYears(),
        _loadClasses(),
        _loadSections(),
        _loadSubjects(),
        _loadFranchises(),
      ]);
      _error = null;
    } catch (e) {
      _error = 'Failed to load academic data: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAcademicYears() async {
    _academicYears = await SupabaseService.getAcademicYears();
  }

  Future<void> _loadClasses() async {
    _classes = await SupabaseService.getClasses();
  }

  Future<void> _loadFranchises() async {
    _franchises = await SupabaseService.getFranchises();
  }

  Future<void> _loadSections() async {
    _sections = await SupabaseService.getSections();
  }


  // Academic Years CRUD
  Future<void> addAcademicYear(AcademicYear year) async {
    print('addAcademicYear printed .............');
    _setLoading(true);
    try {
      final newYear = await SupabaseService.createAcademicYear(year);
      print(newYear);
      _academicYears.add(newYear);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add academic year: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAcademicYear(AcademicYear year) async {
    _setLoading(true);
    try {
      final updatedYear = await SupabaseService.updateAcademicYear(year);
      final index = _academicYears.indexWhere((y) => y.id == year.id);
      if (index != -1) {
        _academicYears[index] = updatedYear;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update academic year: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAcademicYear(String id) async {
    _setLoading(true);
    try {
      await SupabaseService.deleteAcademicYear(id);
      _academicYears.removeWhere((year) => year.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete academic year: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setActiveAcademicYear(String id) async {
    _setLoading(true);
    try {
      await SupabaseService.setActiveAcademicYear(id);

      // Correctly update list using map + copyWith
      _academicYears = _academicYears.map((year) {
        return year.copyWith(isActive: year.id == id);
      }).toList();

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set active year: $e';
      print(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }


  // Classes CRUD
  Future<void> addClass(Class classItem) async {
    _setLoading(true);
    try {
      final newClass = await SupabaseService.createClass(classItem);
      _classes.add(newClass);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add class: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateClass(Class classItem) async {
    _setLoading(true);
    try {
      final updatedClass = await SupabaseService.updateClass(classItem);
      final index = _classes.indexWhere((c) => c.id == classItem.id);
      if (index != -1) {
        _classes[index] = updatedClass;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update class: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteClass(String id) async {
    _setLoading(true);
    try {
      await SupabaseService.deleteClass(id);
      _classes.removeWhere((classItem) => classItem.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete class: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Sections CRUD
  Future<void> addSection(Section section) async {
    _setLoading(true);
    try {
      final newSection = await SupabaseService.createSection(section);
      _sections.add(newSection);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add section: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSection(String id) async {
    _setLoading(true);
    try {
      await SupabaseService.deleteSection(id);
      _sections.removeWhere((section) => section.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete section: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get sections for a specific class
  List<Section> getSectionsForClass(String classId) {
    return _sections.where((section) => section.classId == classId).toList();
  }

  // ------------- subjects CRUD -------------------------

  Future<void> addSubject(Subject subject) async {
    _setLoading(true);
    try {
      final newSubject = await SupabaseService.createSubject(subject);
      _subjects.add(newSubject);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add subject: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSubject(Subject subject) async {
    _setLoading(true);
    try {
      final updatedSubject = await SupabaseService.updateSubject(subject);
      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = updatedSubject;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update subject: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSubject(String id) async {
    _setLoading(true);
    try {
      await SupabaseService.deleteSubject(id);
      _subjects.removeWhere((subject) => subject.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete subject: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

// Get subjects for a specific class
  List<Subject> getSubjectsForClass(String classId) {
    return _subjects.where((subject) => subject.classId == classId).toList();
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
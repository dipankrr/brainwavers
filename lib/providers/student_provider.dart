import 'package:flutter/foundation.dart';
import '../models/franchise_model.dart';
import '../models/student_model.dart';
import '../models/academic_year_model.dart';
import '../models/class_model.dart';
import '../models/section_model.dart';
import '../services/supabase_service.dart';

class StudentProvider with ChangeNotifier {
  // -------------------------
  // DATA LISTS
  // -------------------------
  List<Student> _students = [];
  List<AcademicYear> _academicYears = [];
  List<Class> _classes = [];
  List<Section> _sections = [];
  List<Franchise> _franchises = [];

  // -------------------------
  // FILTER STATES
  // -------------------------
  String? _selectedAcademicYearId;
  String? _selectedClassId;
  String? _selectedSectionId;

  // -------------------------
  // SEARCH STATES
  // -------------------------
  String searchName = "";
  String searchRoll = "";
  String searchAdmission = "";
  String searchFather = "";

  // -------------------------
  // SORT STATES
  // -------------------------
  String sortColumn = "name"; // name | roll | admission | father
  bool sortAsc = true;

  // -------------------------
  // LOADING / ERROR
  // -------------------------
  bool _isLoading = false;
  String? _error;

  // -------------------------
  // GETTERS
  // -------------------------
  List<Student> get students => _students;
  List<AcademicYear> get academicYears => _academicYears;
  List<Class> get classes => _classes;
  List<Section> get sections => _sections;
  List<Franchise> get franchises => _franchises;

  String? get selectedAcademicYearId => _selectedAcademicYearId;
  String? get selectedClassId => _selectedClassId;
  String? get selectedSectionId => _selectedSectionId;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Student> get pendingStudents {
    // Filter students based on 'sent' status
    print('_students');
    List<Student> list = [..._students];
     list = list.where((student) => student.status == 'sent').toList();
    print(list);
    print(list.length);
    return list;
  }


  List<Student> get filteredStudents {

    if (_selectedAcademicYearId == null) {
      return [];
    }
    var filtered = _students;

    if (_selectedAcademicYearId != null) {
      filtered = filtered
          .where((student) => student.admissionYearId == _selectedAcademicYearId)
          .toList();
    }

    if (_selectedClassId != null) {
      filtered = filtered
          .where((student) => student.classId == _selectedClassId)
          .toList();
    }

    return filtered;
  }


  // Filtered students for table (filter -> search -> sort)
  List<Student> get tableStudents {
    // 1️⃣ Start with a full copy of all students
    List<Student> list = [..._students];

    // 2️⃣ SORT first - before filtering or searching
    list.sort((a, b) {
      switch (sortColumn) {

      // -------------------
      // SORT ROLL NUMBER
      // -------------------
        case "roll":
          int r1 = int.tryParse(a.rollNumber.toString()) ?? 0;
          int r2 = int.tryParse(b.rollNumber.toString()) ?? 0;
          return sortAsc ? r1.compareTo(r2) : r2.compareTo(r1);

      // -------------------
      // SORT ADMISSION CODE
      // -------------------
        case "admission":
          String ad1 = (a.admissionCode ?? "").toLowerCase();
          String ad2 = (b.admissionCode ?? "").toLowerCase();
          return sortAsc ? ad1.compareTo(ad2) : ad2.compareTo(ad1);

      // -------------------
      // SORT FATHER NAME
      // -------------------
        case "father":
          String f1 = (a.fatherName ?? "").toLowerCase();
          String f2 = (b.fatherName ?? "").toLowerCase();
          return sortAsc ? f1.compareTo(f2) : f2.compareTo(f1);

      // -------------------
      // SORT NAME (default)
      // -------------------
        case "name":
        default:
          String n1 = a.name.toLowerCase();
          String n2 = b.name.toLowerCase();
          return sortAsc ? n1.compareTo(n2) : n2.compareTo(n1);
      }
    });


    // 3️⃣ Apply FILTERS after sorting
    if (_selectedAcademicYearId != null) {
      list = list
          .where((s) => s.admissionYearId == _selectedAcademicYearId)
          .toList();
    }
    if (_selectedClassId != null) {
      list = list.where((s) => s.classId == _selectedClassId).toList();
    }

    // 4️⃣ Apply SEARCH after sorting & filtering
    if (searchName.isNotEmpty) {
      list = list
          .where((s) => s.name.toLowerCase().contains(searchName.toLowerCase()))
          .toList();
    }
    if (searchRoll.isNotEmpty) {
      list = list
          .where((s) => s.rollNumber.toString().contains(searchRoll))
          .toList();
    }
    if (searchAdmission.isNotEmpty) {
      list = list
          .where((s) => (s.admissionCode ?? "")
          .toLowerCase()
          .contains(searchAdmission.toLowerCase()))
          .toList();
    }
    if (searchFather.isNotEmpty) {
      list = list
          .where((s) => (s.fatherName ?? "")
          .toLowerCase()
          .contains(searchFather.toLowerCase()))
          .toList();
    }

    return list;
  }

  // Sections for selected class
  List<Section> get sectionsForSelectedClass {
    if (_selectedClassId == null) return [];
    return _sections.where((s) => s.classId == _selectedClassId).toList();
  }

  // -------------------------
  // FILTER SETTERS
  // -------------------------
  void setAcademicYearFilter(String? id) {
    _selectedAcademicYearId = id;
    notifyListeners();
  }

  void setClassFilter(String? id) {
    _selectedClassId = id;
    _selectedSectionId = null; // reset section
    notifyListeners();
  }

  void setSectionFilter(String? id) {
    _selectedSectionId = id;
    notifyListeners();
  }

  void clearFilters() {
    _selectedAcademicYearId = null;
    _selectedClassId = null;
    _selectedSectionId = null;

    searchName = "";
    searchRoll = "";
    searchAdmission = "";
    searchFather = "";

    notifyListeners();
  }

  // -------------------------
  // SEARCH SETTERS
  // -------------------------
  void searchByName(String val) {
    searchName = val;
    notifyListeners();
  }

  void searchByRoll(String val) {
    searchRoll = val;
    notifyListeners();
  }

  void searchByAdmission(String val) {
    searchAdmission = val;
    notifyListeners();
  }

  void searchByFather(String val) {
    searchFather = val;
    notifyListeners();
  }

  // -------------------------
  // SORT SETTER
  // -------------------------
  void sortByColumn(String column) {
    if (sortColumn == column) {
      sortAsc = !sortAsc;
    } else {
      sortColumn = column;
      sortAsc = true;
    }
    notifyListeners();
  }

  // -------------------------
  // LOADERS
  // -------------------------
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await loadInitialData();
    _initialized = true;
  }

  Future<void> loadInitialData() async {
    await _loadAcademicYears();
    await _loadClasses();
    await _loadSections();
    await _loadStudents();
    await _loadFranchises();
  }

  Future<void> _loadFranchises() async {
    _setLoading(true);
    try {
      _franchises = await SupabaseService.getFranchises();
      _error = null;
    } catch (e) {
      _error = 'Failed to load franchises: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadStudents() async {
    _setLoading(true);
    try {
      _students = await SupabaseService.getStudents();
      _error = null;
    } catch (e) {
      _error = 'Failed to load students: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAcademicYears() async {
    try {
      _academicYears = await SupabaseService.getAcademicYears();
    } catch (e) {
      _error = 'Failed to load academic years: $e';
    }
  }

  Future<void> _loadClasses() async {
    try {
      _classes = await SupabaseService.getClasses();
    } catch (e) {
      _error = 'Failed to load classes: $e';
    }
  }

  Future<void> _loadSections() async {
    try {
      _sections = await SupabaseService.getSections();
    } catch (e) {
      _error = 'Failed to load sections: $e';
    }
  }

  // -------------------------
  // CRUD
  // -------------------------
  Future<Student> addStudent(Student student) async {
    _setLoading(true);
    try {
      final newStudent = await SupabaseService.createStudent(student);
      _students.add(newStudent);
      _error = null;
      notifyListeners();
      return newStudent;
    } catch (e) {
      _error = 'Failed to add student: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Student> updateStudent(Student student) async {
    _setLoading(true);
    try {
      final updatedStudent = await SupabaseService.updateStudent(student);
      final index = _students.indexWhere((s) => s.id == updatedStudent.id);
      if (index != -1) _students[index] = updatedStudent;
      _error = null;
      notifyListeners();
      return updatedStudent;
    } catch (e) {
      _error = 'Failed to update student: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteStudent(String id) async {
    _setLoading(true);
    try {
      await SupabaseService.deleteStudent(id);
      _students.removeWhere((s) => s.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete student: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // -------------------------
  // INTERNAL
  // -------------------------
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

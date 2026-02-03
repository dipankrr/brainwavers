//final String url = 'https://oopkltlrlnlapqdfjemy.supabase.co'; // Will be configured later
//final String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vcGtsdGxybG5sYXBxZGZqZW15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxODc0MTAsImV4cCI6MjA3Nzc2MzQxMH0.8bS4uCkY1axCsYYJ4oAxlmdC4d10Rdm461xgzYkQCDQ'; // Will be configured later

//import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/franchise_model.dart';
import '../models/mark_model.dart';
import '../models/student_model.dart';
import '../models/academic_year_model.dart';
import '../models/class_model.dart';
import '../models/section_model.dart';
import '../models/subject_model.dart';
//import '../models/subject_model.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
        url:
            'https://eephblcfrrboycinixrp.supabase.co', // Replace with your URL
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlcGhibGNmcnJib3ljaW5peHJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5NzQyNTUsImV4cCI6MjA4NDU1MDI1NX0.f5meKm_X4CAWXGKlKQX0Sh3EsFXJ4GNAQ-g25gSH-PY');
  }

  //------------------------------- RBAC ----------------------------

  static Future<void> printRole() async {
      final user = client.auth.currentUser;
    final role = user?.userMetadata?['role']; // Check the role field in JWT
    print('User role: $role');
    print('User : $user');

    final session = client.auth.currentSession;
    final rolee = session?.user?.userMetadata?['role'];
    final jwt = session?.accessToken;
    print(rolee);
    print(jwt);

// Ensure the token is being passed to the backend for RLS checks.
  }

// Function to create superadmin

  // Helper method to create a user with role-based data and return success/failure
  static Future<bool> _createUser(
      String email, String password, Map<String, dynamic> data) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      print('User created successfully: $response');
      return true; // Return true for success
    } catch (e) {
      print('Failed to create user $e');
      return false; // Return false on failure
    }
  }

  // Create SuperAdmin
  static Future<bool> createSuperAdmin() async {
    return await _createUser(
      'bw@gmail.com',
      'password',
      {
        'role': 'superadmin',
        'email_verified': true,
      },
    );
  }

  // Create Admin
  static Future<bool> createAdmin(
      String adminID,
      String email,
      String password,
      String franchiseId,
      ) async {
    final user = await _createUser(
      email,
      password,
      {
        'role': 'admin',
        'franchise_id': franchiseId,
      },
    );

    if (user == null) return false;

    await client.from('admin_profiles').insert({
      'id': adminID,
      'email': email,
      'role': 'admin',
      'franchise_id': franchiseId,
    });

    return true;
  }

  // static Future<bool> createAdmin(
  //     String id, String password, String franchise) async {
  //   return await _createUser(
  //     id,
  //     password,
  //     {
  //       'role': 'admin',
  //       'email_verified': true,
  //       'franchise_id': franchise,
  //     },
  //   );
  // }

  // Sign-in User
  static Future<AuthResponse?> userSignIn(String id, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: id,
        password: password,
      );
      print('Signed in successfully: $response');
      return response; // Return response on success
    } catch (e) {
      print('Failed to sign in: $e');
      return null; // Return null on failure
    }
  }

  // ------------------- Academic Years CRUD ------------------------
  static Future<List<AcademicYear>> getAcademicYears() async {
    final response = await client
        .from('academic_years')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((map) => AcademicYear.fromMap(map)).toList();
  }

  static Future<AcademicYear> createAcademicYear(AcademicYear year) async {
    print('createAcademicYear printed .............');
    final response = await client
        .from('academic_years')
        .insert(year.toMap())
        .select()
        .single();
    print('ERRROORR:  ' + response.toString());
    return AcademicYear.fromMap(response);
  }

  static Future<AcademicYear> updateAcademicYear(AcademicYear year) async {
    final response = await client
        .from('academic_years')
        .update(year.toMap())
        .eq('id', year.id)
        .select()
        .single();
    return AcademicYear.fromMap(response);
  }

  static Future<void> deleteAcademicYear(String id) async {
    await client.from('academic_years').delete().eq('id', id);
  }

  static Future<void> setActiveAcademicYear(String id) async {
    // 1. Set all rows except selected to inactive
    await client
        .from('academic_years')
        .update({'is_active': false}).neq('id', id);

    // 2. Set selected row to active
    await client
        .from('academic_years')
        .update({'is_active': true}).eq('id', id);
  }

  // ------------------------ Franchise CRUD ---------------------------------------


  static Future<int?> getFranchiseBalance(String franchiseId) async {
    try {
      final response = await client
          .from('franchises')
          .select('balance')
          .eq('id', franchiseId)
          .single();

      return response['balance'] as int?;
    } catch (e) {
      print('Error fetching franchise balance: $e');
      return null;
    }
  }


  Future<List<Map<String, dynamic>>> fetchAdminsForFranchise(String franchiseId) async {
    try {
      final response = await Supabase.instance.client
          .from('auth.users') // Access the auth users table
          .select('id, email, raw_user_meta_data') // Fields you need
          .eq('raw_user_meta_data->>franchise_id', franchiseId) // Filter by franchise_id
          .eq('raw_user_meta_data->>role', 'admin');// Filter by role

      // Since the response is directly a list, you can return it
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching admins: $e");
      return [];
    }
  }





  static Future<List<Map<String, dynamic>>> getAdminsByFranchise(
      String franchiseId,
      ) async {
    final response = await client
        .from('admin_profiles')
        .select()
        .eq('role', 'admin')
        .eq('franchise_id', franchiseId);

    return List<Map<String, dynamic>>.from(response);
  }


  static Future<List<Franchise>> getFranchises() async {
    final response = await client.from('franchises').select();
    return (response as List).map((map) => Franchise.fromMap(map)).toList();
  }

  static Future<Franchise> createFranchise(Franchise franchiseItem) async {
    final response = await client
        .from('franchises')
        .insert(franchiseItem.toMap())
        .select()
        .single();
    return Franchise.fromMap(response);
  }

  static Future<Franchise> updateFranchises(Franchise franchiseItem) async {
    final response = await client
        .from('franchises')
        .update(franchiseItem.toMap())
        .eq('id', franchiseItem.id)
        .select()
        .single();
    return Franchise.fromMap(response);
  }

  static Future<void> deleteFranchise(String id) async {
    await client.from('franchises').delete().eq('id', id);
  }

  // ------------------------ Classes CRUD ---------------------------------------

  static Future<List<Class>> getClasses() async {
    final response = await client
        .from('classes')
        .select()
        .order('order_index', ascending: true);
    return (response as List).map((map) => Class.fromMap(map)).toList();
  }

  static Future<Class> createClass(Class classItem) async {
    final response = await client
        .from('classes')
        .insert(classItem.toMap())
        .select()
        .single();
    return Class.fromMap(response);
  }

  static Future<Class> updateClass(Class classItem) async {
    final response = await client
        .from('classes')
        .update(classItem.toMap())
        .eq('id', classItem.id)
        .select()
        .single();
    return Class.fromMap(response);
  }

  static Future<void> deleteClass(String id) async {
    await client.from('classes').delete().eq('id', id);
  }

  // -----------------------Sections CRUD------------------------------------

  static Future<List<Section>> getSections() async {
    try {
      final response = await client
          .from('sections')
          .select()
          .order('order_index', ascending: true);
      return (response as List).map((map) => Section.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch sections: $e');
    }
  }

  static Future<Section> createSection(Section section) async {
    final response =
        await client.from('sections').insert(section.toMap()).select().single();
    return Section.fromMap(response);
  }

  static Future<void> deleteSection(String id) async {
    await client.from('sections').delete().eq('id', id);
  }

  //-------------------------- Students CRUD-----------------------------------------

  static Future<List<Student>> getStudents() async {
    final response = await client
        .from('students')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((map) => Student.fromMap(map)).toList();
  }

  static Future<Student> createStudent(Student student) async {
    final response =
        await client.from('students').insert(student.toMap()).select().single();
    return Student.fromMap(response);
  }

  static Future<Student> updateStudent(Student student) async {
    final response = await client
        .from('students')
        .update(student.toMap())
        .eq('id', student.id)
        .select()
        .single();
    return Student.fromMap(response);
  }

  static Future<void> deleteStudent(String id) async {
    await client.from('students').delete().eq('id', id);
  }

  // pics crud
  static Future<String> uploadStudentPhoto({
    required String studentId,
    required Uint8List bytes,
  }) async {
    // final now = DateTime.now();
    // final minSec = "${now.minute.toString().padLeft(2, '0')}"
    //     "${now.second.toString().padLeft(2, '0')}";

    final path = '$studentId/profile.jpg';

    await client.storage.from('student-photos').uploadBinary(path, bytes,
        fileOptions: const FileOptions(upsert: true));

    return path; // store in DB
  }

  static Future<void> deleteStudentPhoto(String path) async {
    print("delete photo supabase called ................");
    final deleteRes =
        await client.storage.from('student-photos').remove([path]);
    print(deleteRes);
  }

  // static Future<void> clearPhotoUrl(String studentId) async {
  //   await client.from('students').update({
  //     'photo_url': null,
  //   }).eq('id', studentId);
  // }
  //
  // static Future<void> updatePhotoUrl(String id, String url) async {
  //   await client.from('students').update({
  //     'photo_url': url,
  //   }).eq('id', id);
  // }

  // -------------------------Subjects CRUD--------------------------------

  static Future<List<Subject>> getSubjects() async {
    try {
      final response = await client
          .from('subjects')
          .select()
          .order('order_index', ascending: true);
      return (response as List).map((map) => Subject.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch subjects: $e');
    }
  }

  static Future<Subject> createSubject(Subject subject) async {
    final response =
        await client.from('subjects').insert(subject.toMap()).select().single();
    return Subject.fromMap(response);
  }

  static Future<Subject> updateSubject(Subject subject) async {
    final response = await client
        .from('subjects')
        .update(subject.toMap())
        .eq('id', subject.id)
        .select()
        .single();
    return Subject.fromMap(response);
  }

  static Future<void> deleteSubject(String id) async {
    await client.from('subjects').delete().eq('id', id);
  }

  //------------------------- Marks CRUD ---------------------------------------

  static Future<List<Mark>> getMarks() async {
    try {
      final response = await client
          .from('marks')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((map) => Mark.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch marks: $e');
    }
  }

  static Future<Mark> createMark(Mark mark) async {
    try {
      final response =
          await client.from('marks').insert(mark.toMap()).select().single();
      return Mark.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create mark: $e');
    }
  }

  static Future<Mark> updateMark(Mark mark) async {
    try {
      final response = await client
          .from('marks')
          .update(mark.toMap())
          .eq('id', mark.id)
          .select()
          .single();
      return Mark.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update mark: $e');
    }
  }

  static Future<void> deleteMark(String id) async {
    await client.from('marks').delete().eq('id', id);
  }

// Get marks for specific student, term, and academic year
  static Future<List<Mark>> getStudentMarks({
    required String studentId,
    required String academicYearId,
    required int term,
  }) async {
    try {
      final response = await client
          .from('marks')
          .select()
          .eq('student_id', studentId)
          .eq('academic_year_id', academicYearId)
          .eq('term', term);

      return (response as List).map((map) => Mark.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch student marks: $e');
    }
  }

  static Future<Mark> upsertMark(Mark mark) async {
    try {
      // Check if mark exists
      final existingMarks = await client
          .from('marks')
          .select()
          .eq('student_id', mark.studentId)
          .eq('subject_id', mark.subjectId)
          .eq('academic_year_id', mark.academicYearId)
          .eq('term', mark.term);

      if ((existingMarks as List).isEmpty) {
        // Create new mark
        return await createMark(mark);
      } else {
        // Update existing mark
        final existingMark = Mark.fromMap(existingMarks[0]);
        return await updateMark(mark.copyWith(id: existingMark.id));
      }
    } catch (e) {
      throw Exception('Failed to upsert mark: $e');
    }
  }

  // static Future<Mark> saveMark(Mark mark) async {
  //   final response = await client
  //       .from('marks')
  //       .upsert(mark.toMap())
  //       .select()
  //       .single();
  //
  //   if (response == null) {
  //     throw Exception('saveMark returned no row');
  //   }
  //
  //   return Mark.fromMap(response);
  // }

  //---------------------------------// DASHBOARD STATS //-----------------------------------------------

// Get count of records in a table
  static Future<int> getCount(String tableName) async {
    try {
      final count = await Supabase.instance.client
          .from(tableName)
          .count(); // returns exact count by default

      return count;
    } catch (e) {
      throw Exception('Failed to get count from $tableName: $e');
    }
  }

// Get active academic year
  static Future<String?> getActiveAcademicYear() async {
    try {
      final response = await client
          .from('academic_years')
          .select('year')
          .eq('is_active', true)
          .single();
      return response['year'];
    } catch (e) {
      return null;
    }
  }

// Get students count by class
  static Future<Map<String, int>> getStudentsCountByClass() async {
    try {
      final response = await client.from('students').select('class_id');

      // Count students per class
      final Map<String, int> countMap = {};
      for (var student in response) {
        final classId = student['class_id'];
        countMap[classId] = (countMap[classId] ?? 0) + 1;
      }

      return countMap;
    } catch (e) {
      throw Exception('Failed to get students count by class: $e');
    }
  }

  //--------------------------------------------------------------------------------

  // Helper to check connection
  static Future<bool> testConnection() async {
    try {
      await client.from('academic_years').select('count').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}

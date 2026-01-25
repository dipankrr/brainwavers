import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/responsive_dropdown.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../providers/marks_provider.dart';
import '../../providers/academic_data_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/mark_model.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class EnterMarksScreen extends StatefulWidget {
  const EnterMarksScreen({super.key});

  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  Student? _selectedStudent;
  int? _selectedTerm;
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, bool> _absentStatus = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);

    await studentProvider.loadInitialData();
    await academicProvider.loadAcademicData();
  }

  List<Subject> getSubjectsForStudent() {
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);
    if (_selectedStudent == null) return [];

    return academicProvider.getSubjectsForClass(_selectedStudent!.classId);
  }

  Future<void> _loadStudentMarks() async {
    if (_selectedStudent == null) return;

    final marksProvider = Provider.of<MarksProvider>(context, listen: false);
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);

    final activeYear = academicProvider.academicYears.firstWhere(
          (year) => year.isActive,
      orElse: () => academicProvider.academicYears.first,
    );

    // CRITICAL: Load all marks first
    await marksProvider.loadMarks();

    final studentMarks = marksProvider.getMarksForFilters(
      academicYearId: activeYear.id,
      classId: _selectedStudent!.classId,
      term: _selectedTerm ?? 1,
    ).where((mark) => mark.studentId == _selectedStudent!.id).toList();

    // Initialize controllers with existing marks
    for (final mark in studentMarks) {
      _marksControllers[mark.subjectId] = TextEditingController(
        text: mark.isAbsent ? '' : mark.marksObtained.toString(),
      );
      _absentStatus[mark.subjectId] = mark.isAbsent;
    }

    // Initialize controllers for subjects without marks
    for (final subject in getSubjectsForStudent()) {
      if (!_marksControllers.containsKey(subject.id)) {
        _marksControllers[subject.id] = TextEditingController();
        _absentStatus[subject.id] = false;
      }
    }

    setState(() {});
  }

  Future<void> _saveMarks() async {
    if (_selectedStudent == null) {
      _showError('Please select a student');
      return;
    }

    final marksProvider = Provider.of<MarksProvider>(context, listen: false);
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);

    final activeYear = academicProvider.academicYears.firstWhere(
          (year) => year.isActive,
      orElse: () => academicProvider.academicYears.first,
    );

    bool hasErrors = false;

    for (final subject in getSubjectsForStudent()) {
      final controller = _marksControllers[subject.id];
      final isAbsent = _absentStatus[subject.id] ?? false;

      int marksObtained = 0;

      if (!isAbsent) {
        if (controller!.text.isEmpty) {
          _showError('Please enter marks for ${subject.name} or mark as absent');
          hasErrors = true;
          continue;
        }

        marksObtained = int.tryParse(controller.text) ?? 0;
        if (marksObtained > subject.totalMarks) {
          _showError('Marks for ${subject.name} cannot exceed ${subject.totalMarks}');
          hasErrors = true;
          continue;
        }
      }

      final uuid = Uuid();

      final mark = Mark(
        franchiseId: Supabase.instance.client.auth.currentUser!.userMetadata?['franchise_id'] ?? "920709c5-7a0f-41ea-8965-614fe1556a74", //todo: for superadmin create dropdown like student
        id: uuid.v4(), // Will be set by database
        studentId: _selectedStudent!.id,
        subjectId: subject.id,
        academicYearId: activeYear.id,
        term: 1, // Default to term 1
        marksObtained: marksObtained,
        isAbsent: isAbsent,
        createdAt: DateTime.now(),
      );

      try {
        await marksProvider.saveMark(mark);
      } catch (e) {
        _showError('Failed to save marks for ${subject.name}: $e');
        hasErrors = true;
      }
    }

    if (!hasErrors) {
      _showSuccess('Marks saved successfully!');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Enter Marks'),
      body: Consumer2<StudentProvider, AcademicDataProvider>(
        builder: (context, studentProvider, academicProvider, child) {
          return Padding(
            padding: EdgeInsets.all(
              ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
            ),
            child: Column(
              children: [
                // Student Selection
                _buildStudentSelection(context, studentProvider),
                const SizedBox(height: 20),

                // Marks Entry Form
                if (_selectedStudent != null) ...[
                  _buildMarksForm(context),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Text(
                        'Please select a student to enter marks',
                        style: AppTextStyles.bodyLarge(context)!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentSelection(BuildContext context, StudentProvider studentProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.responsiveValue(context, 12.0, 16.0, 20.0),
        ),
        child: Column(
          children: [
            Text(
              'Select Student',
              style: AppTextStyles.titleLarge(context),
            ),
            const SizedBox(height: 16),
            ResponsiveDropdown<Student?>(
              label: 'Student',
              value: _selectedStudent,
              items: studentProvider.students.map((student) {
                return DropdownMenuItem<Student?>(
                  value: student,
                  child: Text('${student.name} (Roll: ${student.rollNumber})'),
                );
              }).toList(),
              onChanged: (student) async {
                setState(() {
                  _selectedStudent = student;
                  _marksControllers.clear();
                  _absentStatus.clear();
                });
                if (student != null) {
                  await _loadStudentMarks();
                }
              },
              hint: 'Select Student',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksForm(BuildContext context) {
    final subjects = getSubjectsForStudent();

    if (subjects.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No subjects found for this student\'s class',
            style: AppTextStyles.bodyLarge(context)!.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Text(
            'Enter Marks for ${_selectedStudent!.name}',
            style: AppTextStyles.headlineMedium(context),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return _buildSubjectMarksCard(context, subject);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectMarksCard(BuildContext context, Subject subject) {
    final controller = _marksControllers[subject.id] ?? TextEditingController();
    final isAbsent = _absentStatus[subject.id] ?? false;

    return Card(
      elevation: 1,
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveValue(context, 8.0, 12.0, 16.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.responsiveValue(context, 12.0, 16.0, 20.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subject.name,
                  style: AppTextStyles.titleLarge(context)!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Total: ${subject.totalMarks} | Pass: ${subject.passMarks}',
                  style: AppTextStyles.bodyMedium(context)!.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller,
                    label: 'Marks Obtained',
                    hint: 'Enter marks (0-${subject.totalMarks})',
                    keyboardType: TextInputType.number,
                    // TODO: enabled: !isAbsent,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: CheckboxListTile(
                    title: Text(
                      'Absent',
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    value: isAbsent,
                    onChanged: (value) {
                      setState(() {
                        _absentStatus[subject.id] = value ?? false;
                        if (value == true) {
                          controller.clear();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AdaptiveButton(
      onPressed: _saveMarks,
      text: 'Save All Marks',
      fullWidth: true,
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _marksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
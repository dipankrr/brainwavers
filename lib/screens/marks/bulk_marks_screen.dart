import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/responsive_dropdown.dart';

import '../../providers/marks_provider.dart';
import '../../providers/academic_data_provider.dart';
import '../../providers/student_provider.dart';

import '../../models/mark_model.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';


class BulkMarksScreen extends StatefulWidget {
  const BulkMarksScreen({super.key});

  @override
  State<BulkMarksScreen> createState() => _BulkMarksScreenState();
}

class _BulkMarksScreenState extends State<BulkMarksScreen> {
  String? _selectedAcademicYearId;
  String? _selectedClassId;
  String? _selectedSectionId;
  int _selectedTerm = 1;

  final Map<String, Map<String, TextEditingController>> _marksControllers = {};
  final Map<String, Map<String, bool>> _absentStatus = {};
  bool _isLoadingMarks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final marksProvider = Provider.of<MarksProvider>(context, listen: false);

    await academicProvider.loadAcademicData();
    await studentProvider.loadInitialData();
    await marksProvider.loadMarks(); // Load all marks initially
  }

  List<Student> getFilteredStudents() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    var students = studentProvider.students;

    if (_selectedAcademicYearId != null) {
      students = students.where((student) => student.admissionYearId == _selectedAcademicYearId).toList();
    }

    if (_selectedClassId != null) {
      students = students.where((student) => student.classId == _selectedClassId).toList();
    }

    return students;
  }

  List<Subject> getSubjectsForClass() {
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);
    if (_selectedClassId == null) return [];

    return academicProvider.getSubjectsForClass(_selectedClassId!);
  }

  // CRITICAL FIX: Load existing marks into controllers
  Future<void> _loadExistingMarks() async {
    if (_selectedAcademicYearId == null || _selectedClassId == null) return;

    setState(() {
      _isLoadingMarks = true;
    });

    final marksProvider = Provider.of<MarksProvider>(context, listen: false);
    final students = getFilteredStudents();
    final subjects = getSubjectsForClass();

    // Initialize controllers first
    _initializeControllers();

    // Get existing marks for these filters
    final existingMarks = marksProvider.getMarksForFilters(
      academicYearId: _selectedAcademicYearId!,
      classId: _selectedClassId!,
      sectionId: _selectedSectionId,
      term: _selectedTerm,
    );

    // Populate controllers with existing marks
    for (final mark in existingMarks) {
      final studentId = mark.studentId;
      final subjectId = mark.subjectId;

      if (_marksControllers.containsKey(studentId) &&
          _marksControllers[studentId]!.containsKey(subjectId)) {

        // Update the controller text
        if (!mark.isAbsent) {
          _marksControllers[studentId]![subjectId]!.text = mark.marksObtained.toString();
        }

        // Update absent status
        _absentStatus[studentId]![subjectId] = mark.isAbsent;
      }
    }

    setState(() {
      _isLoadingMarks = false;
    });
  }

  void _initializeControllers() {
    final students = getFilteredStudents();
    final subjects = getSubjectsForClass();

    _marksControllers.clear();
    _absentStatus.clear();

    for (final student in students) {
      _marksControllers[student.id] = {};
      _absentStatus[student.id] = {};

      for (final subject in subjects) {
        _marksControllers[student.id]![subject.id] = TextEditingController();
        _absentStatus[student.id]![subject.id] = false;
      }
    }
  }

  Future<void> _saveAllMarks() async {
    if (_selectedAcademicYearId == null || _selectedClassId == null) {
      _showError('Please select academic year and class');
      return;
    }

    final marksProvider = Provider.of<MarksProvider>(context, listen: false);
    final students = getFilteredStudents();
    final subjects = getSubjectsForClass();

    int savedCount = 0;
    int errorCount = 0;

    for (final student in students) {
      for (final subject in subjects) {
        final controller = _marksControllers[student.id]?[subject.id];
        final isAbsent = _absentStatus[student.id]?[subject.id] ?? false;

        // Skip if no marks entered and not absent
        if ((controller?.text.isEmpty ?? true) && !isAbsent) {
          continue;
        }

        int marksObtained = 0;
        if (!isAbsent) {
          marksObtained = int.tryParse(controller?.text ?? '0') ?? 0;

          // Validate marks
          if (marksObtained > subject.totalMarks) {
            _showError('Marks for ${student.name} in ${subject.name} cannot exceed ${subject.totalMarks}');
            errorCount++;
            continue;
          }
        }

        final uuid = const Uuid();

        final mark = Mark(
          id: uuid.v4(), // Will be set by Supabase
          franchiseId: student.franchiseId,
          studentId: student.id,
          subjectId: subject.id,
          academicYearId: _selectedAcademicYearId!,
          term: _selectedTerm,
          marksObtained: marksObtained,
          isAbsent: isAbsent,
          createdAt: DateTime.now(),
        );

        try {
          await marksProvider.saveMark(mark);
          savedCount++;
        } catch (e) {
          errorCount++;
          print('Error saving mark for ${student.name}: $e');
        }
      }
    }

    // Reload marks after saving to update local state
    await marksProvider.loadMarks();

    if (savedCount > 0) {
      _showSuccess('Successfully saved $savedCount marks!');
    }
    if (errorCount > 0) {
      _showError('Failed to save $errorCount marks. Please try again.');
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
      appBar: const CustomAppBar(title: 'Bulk Marks Entry'),
      body: Consumer2<AcademicDataProvider, StudentProvider>(
        builder: (context, academicProvider, studentProvider, child) {
          return Padding(
            padding: EdgeInsets.only(
              left: ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 18.0),
              right: ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 18.0),
              top: 0,
              bottom: 5,
            ),
            child: Column(
              children: [
                // Filters Section
                _buildFiltersSection(context, academicProvider),
                const SizedBox(height: 20),

                // Loading indicator when fetching marks
                if (_isLoadingMarks) ...[
                  const LoadingIndicator(message: 'Loading existing marks...'),
                  const SizedBox(height: 20),
                ],

                // Marks Table
                if (_selectedAcademicYearId != null && _selectedClassId != null && !_isLoadingMarks) ...[
                  _buildMarksTable(context),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                ] else if (!_isLoadingMarks) ...[
                  Expanded(
                    child: Center(
                      child: Text(
                        'Please select academic year and class',
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

  Widget _buildFiltersSection(
      BuildContext context,
      AcademicDataProvider academicProvider,
      ) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF2F3F5), // lighter, modern card bg
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding:  const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          children: [

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [

                _compactField(
                  context,
                  ResponsiveDropdown<String?>(
                    showLabel: false,
                    label: 'Academic Year',
                    value: _selectedAcademicYearId,
                    items: academicProvider.academicYears.map((year) {
                      return DropdownMenuItem(
                        value: year.id,
                        child: Text('${year.year}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedAcademicYearId = val;
                        _selectedClassId = null;
                        _selectedSectionId = null;
                      });
                      if (val != null) _loadExistingMarks();
                    },
                    hint: 'Academic Year',
                  ),
                ),

                _compactField(
                  context,
                  ResponsiveDropdown<String?>(
                    showLabel: false,
                    label: 'Course *',
                    value: _selectedClassId,
                    items: academicProvider.classes.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedClassId = val;
                        _selectedSectionId = null;
                      });
                      if (val != null) _loadExistingMarks();
                    },
                    hint: 'Course',
                  ),
                ),

                // _compactField(
                //   context,
                //   ResponsiveDropdown<int>(
                //     showLabel: false,
                //     label: 'Term',
                //     value: _selectedTerm,
                //     items: MarksProvider.terms.map((t) {
                //       return DropdownMenuItem(
                //         value: t,
                //         child: Text('Term $t'),
                //       );
                //     }).toList(),
                //     onChanged: (term) {
                //       setState(() => _selectedTerm = term!);
                //       _loadExistingMarks();
                //     },
                //     hint: 'Term',
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Compact field width
  Widget _compactField(BuildContext context, Widget child) {
    final w = MediaQuery.of(context).size.width;

    return SizedBox(
      width: w < 480 ? w : 180,  // <-- SUPER small!
      child: child,
    );
  }


  Widget _buildMarksTable(BuildContext context) {
    final students = getFilteredStudents();
    final subjects = getSubjectsForClass();

    if (students.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No students found for selected filters',
            style: AppTextStyles.bodyLarge(context)!.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (subjects.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No subjects found for selected class',
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${students.length} Students • ${subjects.length} Subjects',
                  style: AppTextStyles.bodyMedium(context)!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildScrollableTable(context, students, subjects),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableTable(BuildContext context, List<Student> students, List<Subject> subjects) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          dataRowMinHeight: 70,
          dataRowMaxHeight: 90,
          headingRowHeight: 50,
          columns: [
            const DataColumn(
              label: SizedBox(
                width: 120,
                child: Text(
                  'Student Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            ...subjects.map((subject) {
              return DataColumn(
                label: SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '(${subject.totalMarks})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
          rows: students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;

            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {

                  return index % 2 == 0
                      ? const Color(0xFFF7F7F7)  // even rows
                      : Colors.white;            // odd rows
                },
              ),
              cells: [
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      student.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                ...subjects.map((subject) {
                  final controller = _marksControllers[student.id]?[subject.id] ?? TextEditingController();
                  final isAbsent = _absentStatus[student.id]?[subject.id] ?? false;

                  return DataCell(
                    Center(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Color(0xFFE0E0E0), width: 1), // COLUMN DIVIDER
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        child: Center(
                          child: SizedBox(
                            width: 120,  // Slightly bigger since spacing was tight
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: controller,
                                    enabled: !isAbsent,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(

                                      hintText: '0-${subject.totalMarks}',
                                      hintStyle: const TextStyle(color: Colors.grey, ),

                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),

                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.black38,
                                          width: 1.5,
                                        ),
                                      ),

                                      // 👇 Black border when focused
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                      ),

                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Absent:', style: TextStyle(fontSize: 10)),
                                    Transform.scale(
                                      scale: 0.75,
                                      child: Checkbox(
                                        value: isAbsent,
                                        side: const BorderSide(color: AppColors.lightRed, width: 2),
                                        fillColor: WidgetStateProperty.resolveWith((states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.red;   // when checked
                                          }
                                          return Colors.transparent;       // when unchecked
                                        }),
                                        onChanged: (value) {
                                          setState(() {
                                            _absentStatus[student.id]![subject.id] = value ?? false;
                                            if (value == true) controller.clear();
                                          });
                                        },
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          }).toList(),

        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AdaptiveButton(
      onPressed: _saveAllMarks,
      text: 'Save All Marks',
      fullWidth: true,
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final studentControllers in _marksControllers.values) {
      for (final controller in studentControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}







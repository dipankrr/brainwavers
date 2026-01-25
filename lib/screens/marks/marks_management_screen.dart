import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
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
import 'bulk_marks_screen.dart';
import 'enter_marks_screen.dart';

class MarksManagementScreen extends StatefulWidget {
  const MarksManagementScreen({super.key});

  @override
  State<MarksManagementScreen> createState() => _MarksManagementScreenState();
}

class _MarksManagementScreenState extends State<MarksManagementScreen> {
  // Local filter state since MarksProvider no longer has them
  String? _selectedAcademicYearId;
  String? _selectedClassId;
  String? _selectedSectionId;
  int _selectedTerm = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final marksProvider = Provider.of<MarksProvider>(context, listen: false);
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    await Future.wait([
      marksProvider.loadMarks(),
      academicProvider.loadAcademicData(),
      studentProvider.loadInitialData(),
    ]);
  }

  void _navigateToEnterMarks() {
    if (_selectedAcademicYearId == null || _selectedClassId == null) {
      _showError('Please select academic year and class first');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EnterMarksScreen(),
      ),
    );
  }

  void _navigateToBulkMarks() {
    // TODO: if (_selectedAcademicYearId == null || _selectedClassId == null) {
    //   _showError('Please select academic year and class first');
    //   return;
    // }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BulkMarksScreen(),
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

  // Get filtered marks based on local filter state
  List<Mark> getFilteredMarks(List<Mark> allMarks) {
    if (_selectedAcademicYearId == null && _selectedClassId == null && _selectedTerm == 1) {
      return allMarks;
    }

    var filtered = allMarks;

    if (_selectedAcademicYearId != null) {
      filtered = filtered.where((mark) => mark.academicYearId == _selectedAcademicYearId).toList();
    }

    if (_selectedTerm != 1) {
      filtered = filtered.where((mark) => mark.term == _selectedTerm).toList();
    }

    return filtered;
  }

  // Get student name by ID
  String getStudentName(String studentId, List<Student> students) {
    try {
      return students.firstWhere((student) => student.id == studentId).name;
    } catch (e) {
      return 'Unknown Student';
    }
  }

  // Get subject name by ID
  String getSubjectName(String subjectId, List<Subject> subjects) {
    try {
      return subjects.firstWhere((subject) => subject.id == subjectId).name;
    } catch (e) {
      return 'Unknown Subject';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Marks Management'),
      body: Consumer3<MarksProvider, AcademicDataProvider, StudentProvider>(
        builder: (context, marksProvider, academicProvider, studentProvider, child) {
          if (marksProvider.isLoading || academicProvider.isLoading) {
            return const LoadingIndicator(message: 'Loading data...');
          }

          final filteredMarks = getFilteredMarks(marksProvider.marks);

          return Padding(
            padding:  EdgeInsets.only(
                 left: ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
                 right: ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
                 top: 0,
                 bottom: 0,
          ),

          child: SingleChildScrollView(
              child: Column(
                children: [
                  // Filters Section
                  _buildFiltersSection(context, academicProvider),
                  const SizedBox(height: 20),

                  // Actions Section
                  _buildActionsSection(context),
                  const SizedBox(height: 20),

                  // Marks List
                  _buildMarksList(
                    context,
                    filteredMarks,
                    studentProvider.students,
                    academicProvider.subjects,
                  ),
                ],
              ),
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
      color: const Color(0xFFF2F3F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional title (if you still want it)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Filter Marks',
                style: AppTextStyles.titleLarge(context),
              ),
            ),

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
                        child: Text(
                          '${year.year} ${year.isActive ? "(Active)" : ""}',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedAcademicYearId = val);
                    },
                    hint: 'Academic Year',
                  ),
                ),

                _compactField(
                  context,
                  ResponsiveDropdown<String?>(
                    showLabel: false,
                    label: 'Course',
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
                //     },
                //     hint: 'Term',
                //   ),
                // ),

                /// 🔵 Clear Filters now inside the SAME Wrap → stays in same row.
                if (_selectedAcademicYearId != null ||
                    _selectedClassId != null ||
                    _selectedSectionId != null ||
                    _selectedTerm != 1)
                  _compactField(
                    context,
                    AdaptiveButton(
                      onPressed: () {
                        setState(() {
                          _selectedAcademicYearId = null;
                          _selectedClassId = null;
                          _selectedSectionId = null;
                          _selectedTerm = 1;
                        });
                      },
                      text: 'Clear Filters',
                      backgroundColor: Colors.red,
                      textColor: Colors.red,
                      isOutlined: true,
                      fullWidth: false,
                    ),
                  ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  /// Same compact width logic from your first UI
  Widget _compactField(BuildContext context, Widget child) {
    final w = MediaQuery.of(context).size.width;

    return SizedBox(
      width: w < 480 ? w : 180,
      child: child,
    );
  }


  Widget _buildActionsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Marks Management',
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
        const SizedBox(width: 12),
        AdaptiveButton(
          onPressed: _navigateToBulkMarks,
          text: 'Enter Marks',
        ),
      ],
    );
  }

  Widget _buildMarksList(
      BuildContext context,
      List<Mark> marks,
      List<Student> students,
      List<Subject> subjects,
      ) {
    if (marks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Marks Found',
              style: AppTextStyles.bodyLarge(context)!.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedAcademicYearId != null ||
                  _selectedClassId != null ||
                  _selectedSectionId != null ||
                  _selectedTerm != 1
                  ? 'No marks match your current filters'
                  : 'No marks data available',
              style: AppTextStyles.bodyMedium(context)!.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (marks.isEmpty)
              AdaptiveButton(
                onPressed: _navigateToBulkMarks,
                text: 'Add Marks',
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Marks', '${marks.length}'),
                _buildSummaryItem(
                    'Term $_selectedTerm',
                    'Active'
                ),
                _buildSummaryItem(
                    'Students',
                    '${_getUniqueStudents(marks).length}'
                ),
                _buildSummaryItem(
                    'Subjects',
                    '${_getUniqueSubjects(marks).length}'
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Marks List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          itemCount: marks.length,
          itemBuilder: (context, index) {
            final mark = marks[index];
            return _buildMarkCard(
              context,
              mark,
              getStudentName(mark.studentId, students),
              getSubjectName(mark.subjectId, subjects),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkCard(BuildContext context, Mark mark, String studentName, String subjectName) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveValue(context, 8.0, 12.0, 16.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.responsiveValue(context, 12.0, 16.0, 20.0),
        ),
        child: Row(
          children: [
            // Marks Indicator
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: mark.isAbsent
                    ? AppColors.error.withOpacity(0.1)
                    : (mark.marksObtained > 0
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: mark.isAbsent
                      ? AppColors.error
                      : (mark.marksObtained > 0
                      ? AppColors.success
                      : AppColors.primary),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  mark.isAbsent ? 'A' : '${mark.marksObtained}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: mark.isAbsent
                        ? AppColors.error
                        : (mark.marksObtained > 0
                        ? AppColors.success
                        : AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Mark Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: AppTextStyles.titleLarge(context)!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subjectName,
                    style: AppTextStyles.bodyMedium(context)!.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip('Term ${mark.term}', AppColors.primary),
                      const SizedBox(width: 8),
                      if (mark.isAbsent)
                        _buildInfoChip('Absent', AppColors.error)
                      else
                        _buildInfoChip('Present', AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Created: ${_formatDate(mark.createdAt)}',
                        style: AppTextStyles.bodyMedium(context)!.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            IconButton(
              icon: Icon(
                Icons.visibility,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.primary,
              ),
              onPressed: () {
                // TODO: Implement view mark details
                _showMarkDetails(mark, studentName, subjectName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showMarkDetails(Mark mark, String studentName, String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: $studentName'),
            Text('Subject: $subjectName'),
            Text('Term: ${mark.term}'),
            Text('Marks: ${mark.isAbsent ? "Absent" : mark.marksObtained}'),
            Text('Status: ${mark.isAbsent ? "Absent" : "Present"}'),
            Text('Created: ${_formatDate(mark.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper methods for summary
  List<String> _getUniqueStudents(List<Mark> marks) {
    final studentIds = marks.map((mark) => mark.studentId).toSet();
    return studentIds.toList();
  }

  List<String> _getUniqueSubjects(List<Mark> marks) {
    final subjectIds = marks.map((mark) => mark.subjectId).toSet();
    return subjectIds.toList();
  }
}
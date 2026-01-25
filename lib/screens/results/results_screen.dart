import 'package:flutter/material.dart';
import 'package:brainwavers/services/pdfs/marksheet_pdf_service_landscape.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/responsive_dropdown.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../providers/results_provider.dart';
import '../../providers/academic_data_provider.dart';
import '../../models/result_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // Filter states
  String? _selectedAcademicYearId;
  String? _selectedClassId;
  String? _selectedSectionId;
  int _selectedTerm = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAcademicData();
    });
  }

  Future<void> _loadAcademicData() async {
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);
    await academicProvider.loadAcademicData();
  }

  Future<void> _fetchResults() async {
    if (_selectedAcademicYearId == null || _selectedClassId == null) {
      _showError('Please select academic year and class');
      return;
    }

    final resultsProvider = Provider.of<ResultsProvider>(context, listen: false);

    try {
      await resultsProvider.fetchResults(
        academicYearId: _selectedAcademicYearId!,
        classId: _selectedClassId!,
        sectionId: _selectedSectionId,
        term: _selectedTerm,
      );
    } catch (e) {
      _showError('Failed to fetch results: $e');
    }
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
      appBar: const CustomAppBar(title: 'Results'),
      body: Consumer2<ResultsProvider, AcademicDataProvider>(
        builder: (context, resultsProvider, academicProvider, child) {
          return Padding(
            padding: EdgeInsets.all(
              ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
            ),
            child: Column(
              children: [
                // Filters Section
                _buildFiltersSection(context, academicProvider),
                const SizedBox(height: 20),

                // Fetch Results Button
                if (_selectedAcademicYearId != null && _selectedClassId != null)
                  Row(
                    children: [
                      Expanded(
                        child: AdaptiveButton(
                          onPressed: resultsProvider.isLoading ? null : _fetchResults,
                          text: resultsProvider.isLoading
                              ? 'Loading Results...'
                              : 'View Results',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdaptiveButton(
                          onPressed: resultsProvider.results.isEmpty ? null : () async {
                            final pdfBytes = await MarksheetPdfServiceLandscape.generateBulk(
                              results: context.read<ResultsProvider>().results,
                              term: _selectedTerm,
                              schoolName: 'Your School Name',
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfPreview(
                                  canChangePageFormat: false,
                                  build: (_) => Future.value(pdfBytes),
                                ),
                              ),
                            );
                          },

                          text: 'Bulk Marksheet',
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          textColor: AppColors.primary,
                        ),

                      ),
                    ],
                  ),


                const SizedBox(height: 20),

                // Results Table
                _buildResultsSection(context, resultsProvider),
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
      elevation: 1,
      color: Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _compactField(
              context,
              ResponsiveDropdown<String?>(
                showLabel: false,
                value: _selectedAcademicYearId,
                items: academicProvider.academicYears.map((year) {
                  return DropdownMenuItem<String?>(
                    value: year.id,
                    child: Text('${year.year}${year.isActive ? ' (Active)' : ''}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAcademicYearId = value);
                },
                hint: 'Academic Year *',
              ),
            ),

            _compactField(
              context,
              ResponsiveDropdown<String?>(
                showLabel: false,
                value: _selectedClassId,
                items: academicProvider.classes.map((c) {
                  return DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClassId = value;
                    _selectedSectionId = null;
                  });
                },
                hint: 'Class *',
              ),
            ),

            if (_selectedClassId != null)
              _compactField(
                context,
                ResponsiveDropdown<String?>(
                  showLabel: false,
                  value: _selectedSectionId,
                  items: academicProvider
                      .getSectionsForClass(_selectedClassId!)
                      .map((sec) {
                    return DropdownMenuItem<String?>(
                      value: sec.id,
                      child: Text(sec.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSectionId = value);
                  },
                  hint: 'Section',
                ),
              ),

            _compactField(
              context,
                ResponsiveDropdown<int>(
                  showLabel: false,
                  value: _selectedTerm,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Term 1')),
                    DropdownMenuItem(value: 2, child: Text('Term 2')),
                    DropdownMenuItem(value: 3, child: Text('Term 3')),
                    DropdownMenuItem(value: 4, child: Text('Final')), // Treat as Term 3
                  ],
                  onChanged: (value) {
                    // If 'Final' (value 4) is selected, treat it as Term 3
                    setState(() {
                      _selectedTerm = (value == 3) ? 3 : value!;
                       _fetchResults();
                    });
                  },
                  hint: 'Term *',
                )

            ),

            if (_selectedAcademicYearId != null ||
                _selectedClassId != null ||
                _selectedSectionId != null ||
                _selectedTerm != null)
              SizedBox(
                width: 120,
                child: AdaptiveButton(
                  text: 'Clear',
                  onPressed: () {
                    setState(() {
                      _selectedAcademicYearId = null;
                      _selectedClassId = null;
                      _selectedSectionId = null;
                      _selectedTerm = 1;
                    });
                  },
                  backgroundColor: Colors.red.shade100,
                  textColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _compactField(BuildContext context, Widget child) {
    final w = MediaQuery.of(context).size.width;
    return SizedBox(
      width: w < 480 ? w : 180,
      child: child,
    );
  }



  Widget _buildResultsSection(BuildContext context, ResultsProvider resultsProvider) {
    if (resultsProvider.isLoading) {
      return const Expanded(
        child: LoadingIndicator(message: 'Calculating results...'),
      );
    }

    if (resultsProvider.error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Results',
                style: AppTextStyles.headlineMedium(context)!.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                resultsProvider.error!,
                style: AppTextStyles.bodyMedium(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (resultsProvider.results.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assessment_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Results Found',
                style: AppTextStyles.bodyLarge(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedAcademicYearId != null || _selectedClassId != null
                    ? 'No results available for the selected filters'
                    : 'Please select academic year, class, and term to view results',
                style: AppTextStyles.bodyMedium(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: _buildResultsTable(context, resultsProvider),
    );
  }

  Widget _buildResultsTable(BuildContext context, ResultsProvider resultsProvider) {
    final results = resultsProvider.results;
    final firstResult = results.first;
    final subjects = firstResult.subjectResults.values.map((sr) => sr.subject).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.1)),
          columnSpacing: 12,
          dataRowMinHeight: 40,
          headingRowHeight: 50,
          columns: [
            // Student Info Columns
            const DataColumn(label: Text('Roll No')),
            const DataColumn(label: Text('Name')),
            const DataColumn(label: Text('PDF')),

            // Subject Columns
            for (final subject in subjects)
              if (_selectedTerm == 4)
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subject.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'Term 3 / Yearly',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                )
              else
                DataColumn(
                  label: SizedBox(
                    width: 80,
                    child: Text(
                      subject.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

            // Total Columns
            const DataColumn(label: Text('Total')),
            const DataColumn(label: Text('Percentage')),
            const DataColumn(label: Text('Grade')),
          ],
          rows: results.map((result) {
            return DataRow(
              cells: [
                // Roll No
                DataCell(Text(result.student.rollNumber)),

                // Name
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      result.student.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // PDF Icon
                DataCell(
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () async {
                      final pdfBytes = await MarksheetPdfServiceLandscape.generateBulk(
                        results: [result],
                        term: _selectedTerm,
                        schoolName: 'Your School Name',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfPreview(
                            canChangePageFormat: false,
                            build: (_) => Future.value(pdfBytes),
                          ),
                        ),
                      );

                    },

                  ),
                ),


                // Subject Marks
                for (final subject in subjects)
                  DataCell(
                    _buildSubjectCell(
                      result.subjectResults[subject.id]!,
                      _selectedTerm,
                    ),
                  ),

                // Total Marks
                DataCell(
                  Text(
                    '${result.termResult.totalMarksObtained}/${result.termResult.totalMaxMarks}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: result.termResult.grade == 'F'
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ),

                // Percentage
                DataCell(
                  Text(
                    '${result.termResult.percentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getPercentageColor(result.termResult.percentage),
                    ),
                  ),
                ),

                // Grade
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getGradeColor(result.termResult.grade),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.termResult.grade,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubjectCell(SubjectResult subjectResult, int term) {
    if (term ==4 ) {
      // For term 3, show two lines: Term 3 marks and Yearly total
      return SizedBox(
        width: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subjectResult.isAbsent ? 'AB' : '${subjectResult.totalMarks}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: subjectResult.isAbsent
                    ? AppColors.error
                    : _getMarksColor(subjectResult.totalMarks, subjectResult.subject.totalMarks),
              ),
            ),
            //const SizedBox(height: 2),
            Text(
              '${subjectResult.yearlyTotal ?? 0}',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
            //const SizedBox(height: 2),
            Text(
              subjectResult.grade,
              style: TextStyle(
                fontSize: 8,
                color: _getGradeColor(subjectResult.grade),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // For term 1 or 2, just show marks and grade
      return SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subjectResult.isAbsent ? 'AB' : '${subjectResult.totalMarks}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: subjectResult.isAbsent
                    ? AppColors.error
                    : _getMarksColor(subjectResult.totalMarks, subjectResult.subject.totalMarks),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subjectResult.grade,
              style: TextStyle(
                fontSize: 10,
                color: _getGradeColor(subjectResult.grade),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper methods for color coding
  Color _getMarksColor(int obtained, int total) {
    final percentage = (obtained / total) * 100;
    if (percentage >= 75) return AppColors.success;
    if (percentage >= 60) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return AppColors.error;
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return AppColors.success;
    if (percentage >= 60) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return AppColors.error;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return Colors.purple;
      case 'A':
        return Colors.blue;
      case 'B+':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.amber;
      case 'F':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
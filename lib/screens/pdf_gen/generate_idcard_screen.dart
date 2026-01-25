import 'package:flutter/material.dart';
import 'package:brainwavers/core/constants/other_constants.dart';
import 'package:brainwavers/screens/students/add_edit_student_screen.dart';
import 'package:provider/provider.dart';
import '../../services/pdfs/id_card_pdf_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/cards/student_card.dart';
import '../../providers/student_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/common/responsive_dropdown.dart';

class GenIDCardScreen extends StatefulWidget {
  const GenIDCardScreen({super.key});

  @override
  State<GenIDCardScreen> createState() => _GenIDCardScreenState();
}

class _GenIDCardScreenState extends State<GenIDCardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<StudentProvider>(context, listen: false);
    await provider.loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: const CustomAppBar(title: 'Card Generation'),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.students.isEmpty) {
            return const LoadingIndicator(message: 'Loading students...');
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveUtils.responsiveValue(context, 8.0, 10.0, 12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters Section
                _buildFiltersSection(context, provider),
                const SizedBox(height: 20),

                // Actions Section
                _buildActionsSection(context, provider),
                const SizedBox(height: 20),

                provider.selectedAcademicYearId == null
                    ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Please select an Academic Year to view students',
                        style: AppTextStyles.bodyLarge(context)!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      StudentTableHeader(
                        onNameSearch: provider.searchByName,
                        onRollSearch: provider.searchByRoll,
                        onAdmissionSearch: provider.searchByAdmission,
                        onFatherSearch: provider.searchByFather,
                        onSort: provider.sortByColumn,
                      ),

                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: provider.tableStudents.isEmpty
                            ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline,
                                    size: 64, color: AppColors.textSecondary),
                                const SizedBox(height: 16),
                                Text(
                                  'No students match your filters',
                                  style: AppTextStyles.bodyLarge(context)!.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            : ListView.builder(
                          itemCount: provider.tableStudents.length,
                          itemBuilder: (context, index) {
                            final student = provider.tableStudents[index];
                            final cardColor = index % 2 == 0
                                ? Colors.grey.shade50
                                : Colors.grey.shade100;

                            return StudentCard(
                              cardColor: cardColor,
                              student: student,
                              onPressedIDGen: () async {

                                if (provider.tableStudents.isEmpty) return;

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: Text('Generating pdf.......', style: TextStyle(color: Colors.white, backgroundColor: Colors.black87),),
                                  ),
                                );

                                try {
                                  await IdCardGenerator.downloadOrPrintPdf(
                                      students: [provider.tableStudents[index]],
                                      backgroundAsset: 'template.png',
                                      fileName: '${student.name.trim().replaceAll(' ', '-')}_id_card.pdf',
                                      classes: provider.classes);
                                } finally {
                                  Navigator.pop(context); // remove the loading dialog
                                }
                              },
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddEditStudentScreen(student: student),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, StudentProvider provider) {
    return Card(
      elevation: 1,
      color: Colors.grey.shade300, // matching compact style
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Students',
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // Academic Year
                _compactField(
                  context,
                  ResponsiveDropdown<String?>(
                    showLabel: false,
                    value: provider.selectedAcademicYearId,
                    items: provider.academicYears.map((year) {
                      return DropdownMenuItem<String?>(
                        value: year.id,
                        child: Text(
                            '${year.year} ${year.isActive ? '(Active)' : ''}'),
                      );
                    }).toList(),
                    onChanged: provider.setAcademicYearFilter,
                    hint: 'Academic Year',
                  ),
                ),

                // Class
                _compactField(
                  context,
                  ResponsiveDropdown<String?>(
                    showLabel: false,
                    value: provider.selectedClassId,
                    items: provider.classes.map((c) {
                      return DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: provider.setClassFilter,
                    hint: 'Class',
                  ),
                ),

                // Section (conditional)
                if (provider.selectedClassId != null)
                  _compactField(
                    context,
                    ResponsiveDropdown<String?>(
                      showLabel: false,
                      value: provider.selectedSectionId,
                      items: provider.sectionsForSelectedClass.map((sec) {
                        return DropdownMenuItem<String?>(
                          value: sec.id,
                          child: Text(sec.name),
                        );
                      }).toList(),
                      onChanged: provider.setSectionFilter,
                      hint: 'Section',
                    ),
                  ),

                // Clear Filters button
                if (provider.selectedAcademicYearId != null ||
                    provider.selectedClassId != null ||
                    provider.selectedSectionId != null)
                  SizedBox(
                    width: 150,
                    child: AdaptiveButton(
                      onPressed: provider.clearFilters,
                      text: 'Clear',
                      isOutlined: false,
                      backgroundColor: Colors.red[100],
                      textColor: Colors.red,
                    ),
                  ),
              ],
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

  Future<void> _generateBulkPdf(context) async {
    final provider = context.read<StudentProvider>();
    final students = provider.tableStudents;

    if (students.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await IdCardGenerator.downloadOrPrintPdf(
        students: students,
        backgroundAsset: 'template.png', //for from asset assets/asset.png
        classes: provider.classes
      );
    } finally {
      Navigator.pop(context); // remove the loading dialog
    }
  }


  Widget _buildActionsSection(BuildContext context, StudentProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Students',
            style: AppTextStyles.headlineMedium(context),
          ),
        ),

        if (provider.tableStudents.isNotEmpty && provider.selectedAcademicYearId != null && provider.selectedClassId != null)
          AdaptiveButton(
            text: "Bulk ID",
            onPressed: () async {

              if (provider.tableStudents.isEmpty) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Text('Generating pdf.......', style: TextStyle(color: Colors.white, backgroundColor: Colors.black87),),
                ),
              );

              try {
                await IdCardGenerator.downloadOrPrintPdf(
                  students: provider.tableStudents,
                  backgroundAsset: 'template.png',
                    classes: provider.classes
                );
              } finally {
                Navigator.pop(context); // remove the loading dialog
              }
            },

            backgroundColor: Colors.green,
            textColor: Colors.white,
          ),

      ],
    );
  }

  Widget _buildErrorState(StudentProvider provider) {
    return Center(
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
            'Error Loading Data',
            style: AppTextStyles.headlineMedium(context)!.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error!,
            style: AppTextStyles.bodyMedium(context)!.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AdaptiveButton(
            onPressed: _loadData,
            text: 'Retry',
          ),
        ],
      ),
    );
  }
}


class StudentTableHeader extends StatelessWidget {
  final Function(String)? onNameSearch;
  final Function(String)? onRollSearch;
  final Function(String)? onAdmissionSearch;
  final Function(String)? onFatherSearch;
  final Function(String)? onSort; // Column key for sorting

  const StudentTableHeader({
    super.key,
    this.onNameSearch,
    this.onRollSearch,
    this.onAdmissionSearch,
    this.onFatherSearch,
    this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    double cellPadding = ResponsiveUtils.responsiveValue(context, 8.0, 10.0, 12.0);
    Widget columnDivider = Container(width: 1, color: Colors.grey.shade300);

    Widget buildColumn(String title, {Function()? onTap, Widget? searchField, int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: AppTextStyles.bodySmallCustom(context)!
                          .copyWith(fontWeight: FontWeight.bold)),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.swap_vert, size: 16, color: Colors.blue,),
                  ]
                ],
              ),
            ),
            if (searchField != null) ...[
              const SizedBox(height: 4),
              searchField,
            ],
          ],
        ),
      );
    }

    InputDecoration inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      isDense: true,
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: cellPadding),
      color: Colors.blue.shade50,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            columnDivider,
            const SizedBox(width: 5),

            // NAME
            buildColumn(
              'Name',
              flex: Int.nameFlex,
              onTap: () => onSort?.call('name'),
              searchField: SizedBox(
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: onNameSearch,
                    decoration: const InputDecoration(
                      labelText: " 🔍",
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

            ),

            columnDivider,

            // ROLL NO
            buildColumn(
              'Roll',
              flex: Int.rollFlex,
              onTap: () => onSort?.call('roll'),
              searchField: SizedBox(
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: onRollSearch,
                    decoration: const InputDecoration(
                      // labelText: " 🔍",
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            columnDivider,

            // ADMISSION CODE
            buildColumn(
              'Ad code',
              flex: Int.admissionCodeFlex,
              onTap: () => onSort?.call('admission'),
              searchField: SizedBox(
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, left: 4),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: onAdmissionSearch,
                    decoration: const InputDecoration(
                      labelText: " 🔍",
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            columnDivider,

            // DOB (no search/sort)
            buildColumn(
              'DOB',
              flex: Int.dobFlex,
            ),

            columnDivider,

            // FATHER NAME
            buildColumn(
              'Father',
              flex: Int.fatherFlex,
              onTap: () => onSort?.call('father'),
              searchField: SizedBox(
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, left: 4),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: onFatherSearch,
                    decoration: const InputDecoration(
                      labelText: " 🔍",
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            columnDivider,

            // bulk
            buildColumn(
              'ID',
              flex: Int.rollFlex,
              // onTap: () {
              //   IDCardPdfService.generatePdf(
              //     students: provider.tableStudents,
              //   );
              // },

            ),

            columnDivider,
          ],
        ),
      ),
    );
  }
}


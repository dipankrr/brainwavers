import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/class_model.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/responsive_dropdown.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../providers/academic_data_provider.dart';
import '../../models/subject_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<AcademicDataProvider>(context, listen: false);
    await provider.loadAcademicData();

    // Select first class by default if available
    if (provider.classes.isNotEmpty && _selectedClassId == null) {
      setState(() {
        _selectedClassId = provider.classes.first.id;
      });
    }
  }

  void _showAddEditDialog({Subject? subject}) {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddEditSubjectDialog(
        subject: subject,
        selectedClassId: _selectedClassId!,
      ),
    );
  }

  void _showDeleteDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => DeleteSubjectDialog(subject: subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Subjects Management'),
      body: Consumer<AcademicDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.classes.isEmpty) {
            return const LoadingIndicator(message: 'Loading subjects...');
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          return Padding(
            padding: EdgeInsets.all(
              ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
            ),
            child: Column(
              children: [
                // Class Filter and Add Button
                _buildHeaderSection(context, provider),
                const SizedBox(height: 20),

                // Subjects List
                _buildSubjectsList(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, AcademicDataProvider provider) {
    return Column(
      children: [
        // Class Filter
        ResponsiveDropdown<String?>(
          label: 'Select Course',
          value: _selectedClassId,
          items: provider.classes.map((classItem) {
            return DropdownMenuItem<String?>(
              value: classItem.id,
              child: Text(classItem.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedClassId = value);
          },
          hint: 'Select Course',
        ),
        const SizedBox(height: 16),

        // Add Button (only show when class is selected)
        if (_selectedClassId != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subjects',
                  style: AppTextStyles.headlineMedium(context),
                ),
              ),
              if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
              AdaptiveButton(
                onPressed: () => _showAddEditDialog(),
                text: 'Add Subject',
              ),
            ],
          ),
      ],
    );
  }

  //   Supabase.instance.client.auth.currentUser?.userMetadata?['role'];

  Widget _buildSubjectsList(BuildContext context, AcademicDataProvider provider) {
    if (_selectedClassId == null) {
      return Expanded(
        child: Center(
          child: Text(
            'Please select a class to view subjects',
            style: AppTextStyles.bodyLarge(context)!.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final subjects = provider.getSubjectsForClass(_selectedClassId!);

    if (subjects.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.subject_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Subjects',
                style: AppTextStyles.bodyLarge(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add subjects for the selected class',
                style: AppTextStyles.bodyMedium(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return _buildSubjectCard(context, subject, provider);
        },
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject, AcademicDataProvider provider) {
    final classItem = provider.classes.firstWhere(
          (c) => c.id == subject.classId,
      orElse: () => Class(id: '', name: 'Unknown', orderIndex: 0, createdAt: DateTime.now()),
    );

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
            // Order Indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${subject.orderIndex}',
                  style: AppTextStyles.bodyMedium(context)!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Subject Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: AppTextStyles.titleLarge(context)!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'For ${classItem.name}',
                    style: AppTextStyles.bodyMedium(context)!.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMarksInfo('Total: ${subject.totalMarks}', AppColors.primary),
                      const SizedBox(width: 16),
                      _buildMarksInfo('Pass: ${subject.passMarks}', AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${_formatDate(subject.createdAt)}',
                    style: AppTextStyles.bodyMedium(context)!.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
            // Actions
            IconButton(
              icon: Icon(
                Icons.edit,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.primary,
              ),
              onPressed: () => _showAddEditDialog(subject: subject),
            ),
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
            IconButton(
              icon: Icon(
                Icons.delete,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.error,
              ),
              onPressed: () => _showDeleteDialog(subject),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksInfo(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorState(AcademicDataProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Add/Edit Subject Dialog
class AddEditSubjectDialog extends StatefulWidget {
  final Subject? subject;
  final String selectedClassId;

  const AddEditSubjectDialog({
    super.key,
    this.subject,
    required this.selectedClassId,
  });

  @override
  State<AddEditSubjectDialog> createState() => _AddEditSubjectDialogState();
}

class _AddEditSubjectDialogState extends State<AddEditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _passMarksController = TextEditingController();
  final _orderController = TextEditingController();
  int? _selectedOrder = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameController.text = widget.subject!.name;
      _totalMarksController.text = widget.subject!.totalMarks.toString();
      _passMarksController.text = widget.subject!.passMarks.toString();
      _orderController.text = widget.subject!.orderIndex.toString();
    } else {
      _totalMarksController.text = '100';
      _passMarksController.text = '40';
      _orderController.text = '1';
    }
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    final totalMarks = int.tryParse(_totalMarksController.text) ?? 100;
    final passMarks = int.tryParse(_passMarksController.text) ?? 40;

    if (passMarks > totalMarks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pass marks cannot be greater than total marks'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<AcademicDataProvider>(context, listen: false);
      final uuid = Uuid();

      final subject = Subject(
        id: widget.subject?.id ?? uuid.v4(),
        classId: widget.selectedClassId,
        name: _nameController.text.trim(),
        totalMarks: totalMarks,
        passMarks: passMarks,
        orderIndex: int.tryParse(_orderController.text) ?? 1,
        createdAt: widget.subject?.createdAt ?? DateTime.now(),
      );

      if (widget.subject == null) {
        await provider.addSubject(subject);
        _showSuccess('Subject added successfully!');
      } else {
        await provider.updateSubject(subject);
        _showSuccess('Subject updated successfully!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save subject: $e');
    } finally {
      setState(() => _isLoading = false);
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
    final provider = Provider.of<AcademicDataProvider>(context, listen: false);
    final classItem = provider.classes.firstWhere(
          (c) => c.id == widget.selectedClassId,
      orElse: () => Class(id: '', name: 'Unknown', orderIndex: 0, createdAt: DateTime.now()),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subject == null ? 'Add Subject' : 'Edit Subject',
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 8),
              Text(
                'For ${classItem.name}',
                style: AppTextStyles.bodyMedium(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _nameController,
                label: 'Subject Name *',
                hint: 'e.g., Mathematics, Science, English',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter subject name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _totalMarksController,
                      label: 'Total Marks *',
                      hint: 'e.g., 100',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter total marks';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _passMarksController,
                      label: 'Pass Marks *',
                      hint: 'e.g., 40',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pass marks';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),


            // DropdownButtonFormField<int>(
            //   value: _selectedOrder,
            //   decoration: const InputDecoration(
            //     labelText: 'Order Index *',
            //     hintText: 'Select order',
            //     border: OutlineInputBorder(),
            //   ),
            //   items: const [
            //     DropdownMenuItem(
            //       value: 1,
            //       child: Text('Academic'),
            //     ),
            //     DropdownMenuItem(
            //       value: 2,
            //       child: Text('CO-CURRICULAR'),
            //     ),
            //     DropdownMenuItem(
            //       value: 3,
            //       child: Text('Personality'),
            //     ),
            //   ],
            //   onChanged: (value) {
            //     setState(() {
            //       _selectedOrder = value;
            //       _orderController.text = value.toString(); // 👈 stores 1, 2, or 3
            //     });
            //   },
            //   validator: (value) {
            //     if (value == null) {
            //       return 'Please select order index';
            //     }
            //     return null;
            //   },
            // ),


            const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      text: 'Cancel',
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: _isLoading ? null : _saveSubject,
                      text: _isLoading ? 'Saving...' : 'Save',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalMarksController.dispose();
    _passMarksController.dispose();
    _orderController.dispose();
    super.dispose();
  }
}

// Delete Subject Dialog
class DeleteSubjectDialog extends StatelessWidget {
  final Subject subject;

  const DeleteSubjectDialog({super.key, required this.subject});

  Future<void> _deleteSubject(BuildContext context) async {
    try {
      final provider = Provider.of<AcademicDataProvider>(context, listen: false);
      await provider.deleteSubject(subject.id);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete subject: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AcademicDataProvider>(context, listen: false);
    final classItem = provider.classes.firstWhere(
          (c) => c.id == subject.classId,
      orElse: () => Class(id: '', name: 'Unknown', orderIndex: 0, createdAt: DateTime.now()),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Subject',
              style: AppTextStyles.headlineMedium(context)!.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${subject.name}" from ${classItem.name}?',
              style: AppTextStyles.bodyLarge(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Marks: ${subject.totalMarks}, Pass Marks: ${subject.passMarks}',
              style: AppTextStyles.bodyMedium(context)!.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: AppTextStyles.bodyMedium(context)!.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: AdaptiveButton(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'Cancel',
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdaptiveButton(
                    onPressed: () => _deleteSubject(context),
                    text: 'Delete',
                    backgroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
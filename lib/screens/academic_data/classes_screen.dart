import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../providers/academic_data_provider.dart';
import '../../models/class_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
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
  }

  void _showAddEditDialog({Class? classItem}) {
    showDialog(
      context: context,
      builder: (context) => AddEditClassDialog(classItem: classItem),
    );
  }

  void _showDeleteDialog(Class classItem) {
    showDialog(
      context: context,
      builder: (context) => DeleteClassDialog(classItem: classItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Courses Management'),
      body: Consumer<AcademicDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.classes.isEmpty) {
            return const LoadingIndicator(message: 'Loading classes...');
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
                // Header and Add Button
                _buildHeaderSection(context),
                const SizedBox(height: 20),

                // Classes List
                _buildClassesList(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Courses',
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
        if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
        AdaptiveButton(
          onPressed: () => _showAddEditDialog(),
          text: 'Add Course',
        ),
      ],
    );
  }

  Widget _buildClassesList(BuildContext context, AcademicDataProvider provider) {
    if (provider.classes.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.class_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Courses',
                style: AppTextStyles.bodyLarge(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first course to get started',
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
        itemCount: provider.classes.length,
        itemBuilder: (context, index) {
          final classItem = provider.classes[index];
          return _buildClassCard(context, classItem, provider, index+1);
        },
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, Class classItem, AcademicDataProvider provider, int index) {
    final subjectsCount = provider.getSubjectsForClass(classItem.id).length;

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
                  index.toString(),
                  style: AppTextStyles.bodyMedium(context)!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Class Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classItem.name,
                    style: AppTextStyles.titleLarge(context)!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$subjectsCount subject${subjectsCount != 1 ? 's' : ''}',
                        style: AppTextStyles.bodyMedium(context)!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                       // width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          //shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            ' 📆 ${classItem.orderIndex} month ',
                            style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${_formatDate(classItem.createdAt)}',
                    style: AppTextStyles.bodyMedium(context)!.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
              IconButton(
              icon: Icon(
                Icons.edit,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.primary,
              ),
              onPressed: () => _showAddEditDialog(classItem: classItem),
            ),
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")
            IconButton(
              icon: Icon(
                Icons.delete,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.error,
              ),
              onPressed: () => _showDeleteDialog(classItem),
            ),
          ],
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

// Add/Edit Class Dialog
class AddEditClassDialog extends StatefulWidget {
  final Class? classItem;

  const AddEditClassDialog({super.key, this.classItem});

  @override
  State<AddEditClassDialog> createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<AddEditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classItem != null) {
      _nameController.text = widget.classItem!.name;
      _orderController.text = widget.classItem!.orderIndex.toString();
    } else {
      _orderController.text = '3';
    }
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<AcademicDataProvider>(context, listen: false);
      final uuid = Uuid();

      final classItem = Class(
        id: widget.classItem?.id ?? uuid.v4(),
        name: _nameController.text.trim(),
        orderIndex: int.tryParse(_orderController.text) ?? 1,
        createdAt: widget.classItem?.createdAt ?? DateTime.now(),
      );

      if (widget.classItem == null) {
        await provider.addClass(classItem);
        _showSuccess('course added successfully!');
      } else {
        await provider.updateClass(classItem);
        _showSuccess('course updated successfully!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save course: $e');
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
                widget.classItem == null ? 'Add Course' : 'Edit Course',
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _nameController,
                label: 'Course Name *',
                hint: 'e.g., course 1, Grade 1',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _orderController,
                label: 'Course Duration in months *', // this was order index
                hint: 'e.g., 3, 12, 18',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Course Duration months'; // this was order index
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
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
                      onPressed: _isLoading ? null : _saveClass,
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
    _orderController.dispose();
    super.dispose();
  }
}

// Delete Class Dialog
class DeleteClassDialog extends StatelessWidget {
  final Class classItem;

  const DeleteClassDialog({super.key, required this.classItem});

  Future<void> _deleteClass(BuildContext context) async {
    try {
      final provider = Provider.of<AcademicDataProvider>(context, listen: false);
      await provider.deleteClass(classItem.id);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('course deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete course: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AcademicDataProvider>(context, listen: false);
    final subjectsCount = provider.getSubjectsForClass(classItem.id).length;

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
              'Delete course',
              style: AppTextStyles.headlineMedium(context)!.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${classItem.name}"?',
              style: AppTextStyles.bodyLarge(context),
            ),
            if (subjectsCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'This will also delete $subjectsCount subject${subjectsCount != 1 ? 's' : ''} associated with this class.',
                style: AppTextStyles.bodyMedium(context)!.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
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
                    onPressed: () => _deleteClass(context),
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/class_model.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/responsive_dropdown.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../providers/academic_data_provider.dart';
import '../../models/section_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
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

  void _showAddEditDialog({Section? section}) {
    showDialog(
      context: context,
      builder: (context) => AddEditSectionDialog(
        section: section,
        selectedClassId: _selectedClassId!,
      ),
    );
  }

  void _showDeleteDialog(Section section) {
    showDialog(
      context: context,
      builder: (context) => DeleteSectionDialog(section: section),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Sections Management'),
      body: Consumer<AcademicDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.classes.isEmpty) {
            return const LoadingIndicator(message: 'Loading sections...');
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

                // Sections List
                _buildSectionsList(context, provider),
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
          label: 'Select Class',
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
          hint: 'Select Class',
        ),
        const SizedBox(height: 16),

        // Add Button (only show when class is selected)
        if (_selectedClassId != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sections',
                  style: AppTextStyles.headlineMedium(context),
                ),
              ),
              AdaptiveButton(
                onPressed: () => _showAddEditDialog(),
                text: 'Add Section',
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionsList(BuildContext context, AcademicDataProvider provider) {
    if (_selectedClassId == null) {
      return Expanded(
        child: Center(
          child: Text(
            'Please select a class to view sections',
            style: AppTextStyles.bodyLarge(context)!.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final sections = provider.getSectionsForClass(_selectedClassId!);

    if (sections.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.layers_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Sections',
                style: AppTextStyles.bodyLarge(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add sections for the selected class',
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
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return _buildSectionCard(context, section, provider);
        },
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, Section section, AcademicDataProvider provider) {
    final classItem = provider.classes.firstWhere(
          (c) => c.id == section.classId,
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
                  '${section.orderIndex}',
                  style: AppTextStyles.bodyMedium(context)!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Section Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${classItem.name} - ${section.name}',
                    style: AppTextStyles.titleLarge(context)!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Section ${section.name}',
                    style: AppTextStyles.bodyMedium(context)!.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${_formatDate(section.createdAt)}',
                    style: AppTextStyles.bodyMedium(context)!.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            IconButton(
              icon: Icon(
                Icons.edit,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.primary,
              ),
              onPressed: () => _showAddEditDialog(section: section),
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.error,
              ),
              onPressed: () => _showDeleteDialog(section),
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

// Add/Edit Section Dialog
class AddEditSectionDialog extends StatefulWidget {
  final Section? section;
  final String selectedClassId;

  const AddEditSectionDialog({
    super.key,
    this.section,
    required this.selectedClassId,
  });

  @override
  State<AddEditSectionDialog> createState() => _AddEditSectionDialogState();
}

class _AddEditSectionDialogState extends State<AddEditSectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.section != null) {
      _nameController.text = widget.section!.name;
      _orderController.text = widget.section!.orderIndex.toString();
    } else {
      _orderController.text = '1';
    }
  }

  Future<void> _saveSection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<AcademicDataProvider>(context, listen: false);
      final uuid = Uuid();

      final section = Section(
        id: widget.section?.id ?? uuid.v4(),
        classId: widget.selectedClassId,
        name: _nameController.text.trim(),
        orderIndex: int.tryParse(_orderController.text) ?? 1,
        createdAt: widget.section?.createdAt ?? DateTime.now(),
      );

      if (widget.section == null) {
        await provider.addSection(section);
        _showSuccess('Section added successfully!');
      } else {
        // For now, we only support adding sections. Editing would require update method.
        _showError('Editing sections not implemented yet');
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save section: $e');
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
                widget.section == null ? 'Add Section' : 'Edit Section',
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 8),
              Text(
                'For ${classItem.name}',
                style: AppTextStyles.bodyMedium(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _nameController,
                label: 'Section Name *',
                hint: 'e.g., A, B, Science, Commerce',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter section name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _orderController,
                label: 'Order Index *',
                hint: 'e.g., 1, 2, 3',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter order index';
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
                      onPressed: _isLoading ? null : _saveSection,
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

// Delete Section Dialog
class DeleteSectionDialog extends StatelessWidget {
  final Section section;

  const DeleteSectionDialog({super.key, required this.section});

  Future<void> _deleteSection(BuildContext context) async {
    try {
      final provider = Provider.of<AcademicDataProvider>(context, listen: false);
      await provider.deleteSection(section.id);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Section deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete section: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AcademicDataProvider>(context, listen: false);
    final classItem = provider.classes.firstWhere(
          (c) => c.id == section.classId,
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
              'Delete Section',
              style: AppTextStyles.headlineMedium(context)!.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${section.name}" from ${classItem.name}?',
              style: AppTextStyles.bodyLarge(context),
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
                    onPressed: () => _deleteSection(context),
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
import 'package:brainwavers/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../providers/academic_data_provider.dart';
import '../../models/academic_year_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class AcademicYearsScreen extends StatefulWidget {
  const AcademicYearsScreen({super.key});

  @override
  State<AcademicYearsScreen> createState() => _AcademicYearsScreenState();
}

class _AcademicYearsScreenState extends State<AcademicYearsScreen> {
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

  void _showAddEditDialog({AcademicYear? year}) {
    showDialog(
      context: context,
      builder: (context) => AddEditAcademicYearDialog(year: year),
    );
  }

  void _showDeleteDialog(AcademicYear year) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(year: year),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Academic Years'),
      body: Consumer<AcademicDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.academicYears.isEmpty) {
            return const LoadingIndicator(message: 'Loading academic years...');
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

                // Academic Years List
                _buildAcademicYearsList(context, provider),
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
            'Academic Years',
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
        if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")

        AdaptiveButton(
          onPressed: () => _showAddEditDialog(),
          text: 'Add Year',
        ),
      ],
    );
  }

  Widget _buildAcademicYearsList(BuildContext context, AcademicDataProvider provider) {
    if (provider.academicYears.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Academic Years',
                style: AppTextStyles.bodyLarge(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first academic year to get started',
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
        itemCount: provider.academicYears.length,
        itemBuilder: (context, index) {
          final year = provider.academicYears[index];
          return _buildAcademicYearCard(context, year, provider);
        },
      ),
    );
  }

  Widget _buildAcademicYearCard(BuildContext context, AcademicYear year, AcademicDataProvider provider) {
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
            // Active Indicator
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: year.isActive ? AppColors.success : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),

            // Year Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    year.year,
                    style: AppTextStyles.titleLarge(context)!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    year.isActive ? 'Active' : 'Inactive',
                    style: AppTextStyles.bodyMedium(context)!.copyWith(
                      color: year.isActive ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${_formatDate(year.createdAt)}',
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
            if (!year.isActive) ...[
              AdaptiveButton(
                onPressed: () => _setActiveYear(year.id, provider),
                text: 'Set Active',
                isOutlined: true,
              ),
              const SizedBox(width: 8),
            ],
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")

            IconButton(
              icon: Icon(
                Icons.edit,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.primary,
              ),
              onPressed: () => _showAddEditDialog(year: year),
            ),
            if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")

            IconButton(
              icon: Icon(
                Icons.delete,
                size: ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.error,
              ),
              onPressed: () => _showDeleteDialog(year),
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

  Future<void> _setActiveYear(String yearId, AcademicDataProvider provider) async {
    try {
      await provider.setActiveAcademicYear(yearId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Academic year set as active'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set active year: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Add/Edit Academic Year Dialog
class AddEditAcademicYearDialog extends StatefulWidget {
  final AcademicYear? year;

  const AddEditAcademicYearDialog({super.key, this.year});

  @override
  State<AddEditAcademicYearDialog> createState() => _AddEditAcademicYearDialogState();
}

class _AddEditAcademicYearDialogState extends State<AddEditAcademicYearDialog> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.year != null) {
      _yearController.text = widget.year!.year;
    }
  }

  Future<void> _saveAcademicYear() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await SupabaseService.printRole();

    try {
      final provider = Provider.of<AcademicDataProvider>(context, listen: false);
      final uuid = Uuid();

      final academicYear = AcademicYear(
        id: widget.year?.id ?? uuid.v4(),
        year: _yearController.text.trim(),
        isActive: widget.year?.isActive ?? false,
        createdAt: widget.year?.createdAt ?? DateTime.now(),
      );

      if (widget.year == null) {
        await provider.addAcademicYear(academicYear);
        _showSuccess('Academic year added successfully!');
      } else {
        await provider.updateAcademicYear(academicYear);
        _showSuccess('Academic year updated successfully!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save academic year: $e');
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
                widget.year == null ? 'Add Academic Year' : 'Edit Academic Year',
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                controller: _yearController,
                label: 'Academic Year *',
                hint: 'e.g., 2024-2025',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter academic year';
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
                      onPressed: _isLoading ? null : _saveAcademicYear,
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
    _yearController.dispose();
    super.dispose();
  }
}

// Delete Confirmation Dialog
class DeleteConfirmationDialog extends StatelessWidget {
  final AcademicYear year;

  const DeleteConfirmationDialog({super.key, required this.year});

  Future<void> _deleteAcademicYear(BuildContext context) async {
    try {
      final provider = Provider.of<AcademicDataProvider>(context, listen: false);
      await provider.deleteAcademicYear(year.id);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Academic year deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete academic year: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Delete Academic Year',
              style: AppTextStyles.headlineMedium(context)!.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${year.year}"?',
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
                    onPressed: () => _deleteAcademicYear(context),
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
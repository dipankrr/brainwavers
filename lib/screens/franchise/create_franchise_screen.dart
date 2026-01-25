import 'package:brainwavers/providers/franchise_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/franchise_model.dart';
import '../../providers/admin_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

class FranchiseScreen extends StatefulWidget {
  const FranchiseScreen({super.key});

  @override
  State<FranchiseScreen> createState() => _FranchiseScreenState();
}

class _FranchiseScreenState extends State<FranchiseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: false);
    await franchiseProvider.loadFranchiseData();

    // Now load the admins for each franchise
    for (var franchise in franchiseProvider.franchises) {
      await Provider.of<AdminProvider>(context, listen: false)
          .loadAdmins(franchise.id);
    }
  }

  void _showAddEditDialog({Franchise? franchiseItem}) {
    showDialog(
      context: context,
      builder: (context) =>
          AddEditFranchiseDialog(franchiseItem: franchiseItem),
    );
  }

  void _showDeleteDialog(Franchise franchiseItem) {
    showDialog(
      context: context,
      builder: (context) => DeleteFranchiseDialog(franchiseItem: franchiseItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Franchise Management'),
      body: Consumer<FranchiseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.franchises.isEmpty) {
            return const LoadingIndicator(message: 'Loading franchises...');
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
                _buildFranchisesList(context, provider),
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
            'Franchises',
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
        AdaptiveButton(
          onPressed: () => _showAddEditDialog(),
          text: 'Add Franchise',
        ),
      ],
    );
  }

  Widget _buildFranchisesList(
      BuildContext context, FranchiseProvider provider) {
    if (provider.franchises.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No Franchises',
                style: AppTextStyles.bodyLarge(context)!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first franchise to get started',
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
        itemCount: provider.franchises.length,
        itemBuilder: (context, index) {
          final franchiseItem = provider.franchises[index];
          return _buildFranchiseCard(context, franchiseItem, provider);
        },
      ),
    );
  }

  Widget _buildFranchiseCard(BuildContext context, Franchise franchiseItem,
      FranchiseProvider provider) {
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
                child: Icon(Icons.store),
              ),
            ),
            const SizedBox(width: 16),

            // Franchise Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    franchiseItem.name,
                    style: AppTextStyles.titleLarge(context)!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${_formatDate(franchiseItem.createdAt)}',
                    style: AppTextStyles.bodyMedium(context)!.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Admins Section
                  Consumer<AdminProvider>(
                    builder: (context, adminProvider, child) {
                      final admins = adminProvider.getAdmins(franchiseItem.id);
                      if (adminProvider.isLoading) {
                        return const CircularProgressIndicator();
                      }

                      if (adminProvider.error != null) {
                        return Text('Error: ${adminProvider.error}');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var admin in admins)
                            Text(
                              admin[
                                  'email'], // You can also add more fields here, like role
                              style: AppTextStyles.bodyMedium(context),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text("Add Admin"),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddAdminDialog(
                                      franchiseId:
                                          franchiseItem.id, // Pass franchise ID
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add_circle),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Actions
            IconButton(
              icon: Icon(
                Icons.edit,
                size:
                    ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.primary,
              ),
              onPressed: () => _showAddEditDialog(franchiseItem: franchiseItem),
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                size:
                    ResponsiveUtils.responsiveValue(context, 18.0, 20.0, 22.0),
                color: AppColors.error,
              ),
              onPressed: () => _showDeleteDialog(franchiseItem),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(FranchiseProvider provider) {
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

//========================================= add admin dialog =============================

class AddAdminDialog extends StatefulWidget {
  final String franchiseId;

  const AddAdminDialog({super.key, required this.franchiseId});

  @override
  _AddAdminDialogState createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // This method now uses AdminProvider for adding the admin
  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Use AdminProvider to add the admin
      final success = await Provider.of<AdminProvider>(context, listen: false)
          .addAdmin(
        id: _idController.text.trim(),
        password: _passwordController.text.trim(),
        franchiseId: widget.franchiseId,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        _showError('Failed to create admin');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                'Add Admin',
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _idController,
                label: 'Admin Email / ID *',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter admin id';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Password *',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
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
                      onPressed: _isLoading ? null : _createAdmin,
                      text: _isLoading ? 'Creating...' : 'Save',
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
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}


// ==============================================================================

// Add/Edit Franchise Dialog
class AddEditFranchiseDialog extends StatefulWidget {
  final Franchise? franchiseItem;

  const AddEditFranchiseDialog({super.key, this.franchiseItem});

  @override
  State<AddEditFranchiseDialog> createState() => _AddEditFranchiseDialogState();
}

class _AddEditFranchiseDialogState extends State<AddEditFranchiseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.franchiseItem != null) {
      _nameController.text = widget.franchiseItem!.name;
    }
  }

  Future<void> _saveFranchise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<FranchiseProvider>(context, listen: false);
      final uuid = Uuid();

      final franchiseItem = Franchise(
        id: widget.franchiseItem?.id ?? uuid.v4(),
        name: _nameController.text.trim(),
        createdAt: widget.franchiseItem?.createdAt ?? DateTime.now(),
      );

      if (widget.franchiseItem == null) {
        await provider.addFranchise(franchiseItem);
        _showSuccess('Franchise added successfully!');
      } else {
        await provider.updateFranchise(franchiseItem);
        _showSuccess('Franchise updated successfully!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save class: $e');
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
                widget.franchiseItem == null
                    ? 'Add Franchise'
                    : 'Edit Franchise',
                style: AppTextStyles.headlineMedium(context),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _nameController,
                label: 'Franchise Name *',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter franchise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AdaptiveButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      text: 'Cancel',
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdaptiveButton(
                      onPressed: _isLoading ? null : _saveFranchise,
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
    super.dispose();
  }
}

// Delete Franchise Dialog
class DeleteFranchiseDialog extends StatelessWidget {
  final Franchise franchiseItem;

  const DeleteFranchiseDialog({super.key, required this.franchiseItem});

  Future<void> _deleteFranchise(BuildContext context) async {
    try {
      final provider = Provider.of<FranchiseProvider>(context, listen: false);
      await provider.deleteFranchise(franchiseItem.id);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Franchise deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete franchise: $e'),
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
              'Delete Franchise',
              style: AppTextStyles.headlineMedium(context)!.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${franchiseItem.name}"?',
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
                    onPressed: () => _deleteFranchise(context),
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

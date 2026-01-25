import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/class_model.dart';
import '../../services/pdfs/student_form_pdf_service.dart';
import '../../services/pick_image/photo_picker.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/bottom_navbar.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/adaptive_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/responsive_dropdown.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;


class AddEditStudentScreen extends StatefulWidget {
  final Student? student;

  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Photo state
  String? _photoUrl;     // existing saved photo
  Uint8List? _photoBytes; // new picked image (for preview & upload)
  bool _photoRemoved = false; // user removed photo

  // Controllers for all fields
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _aadharController = TextEditingController();
  final _motherTongueController = TextEditingController(text: 'Bengali');

  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();

  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _emailController = TextEditingController();

  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _districtController = TextEditingController(text: "South Dinajpur");

  final _admissionCodeController = TextEditingController();
  final _refNoDateController = TextEditingController();
  final _rollNumberController = TextEditingController();

  // Dropdown values
  String? _selectedAcademicYearId;
  String? _selectedClassId;
  String? _selectedFranchiseId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().ensureInitialized();
    });
   // _photoUrl = widget.student?.photoUrl;
  }

  void _initializeForm() {
    if (widget.student != null) {
      _photoUrl = widget.student?.photoUrl;

      // Edit mode - populate fields
      final student = widget.student!;

      _nameController.text = student.name;
      _dobController.text = student.dob != null
          ? DateFormat('dd/MM/yyyy').format(student.dob!)
          : '';
      _genderController.text = student.gender ?? '';
      _aadharController.text = student.aadharNumber ?? '';
      _motherTongueController.text = student.motherTongue ?? '';

      _fatherNameController.text = student.fatherName ?? '';
      _motherNameController.text = student.motherName ?? '';

      _phoneController.text = student.phoneNumber ?? '';
      _phone2Controller.text = student.phoneNumber2 ?? '';
      _emailController.text = student.email ?? '';

      _addressController.text = student.address ?? '';
      _pincodeController.text = student.pincode ?? '';
      _districtController.text = student.district ?? '';

      _admissionCodeController.text = student.admissionCode ?? '';
      _refNoDateController.text = student.refNoDate != null
          ? DateFormat('dd/MM/yyyy').format(student.refNoDate!)
          : '';
      _rollNumberController.text = student.rollNumber;

      _selectedAcademicYearId = student.admissionYearId;
      _selectedClassId = student.classId;
      _selectedFranchiseId = student.franchiseId;
    }
  }


  Future<void> _pickPhoto() async {
    try {
      final bytes = await PhotoPickerService.instance.pickPhoto();
      if (bytes == null) return;

      // Size check
      if (bytes.length / 1024 > 150) {
        _showError("Image must be less than 150 KB.");
        return;
      }

      setState(() {
        _photoBytes = bytes;
        _photoRemoved = false;
        _photoUrl = null;
      });

    } catch (e) {
      _showError("Failed to pick image: $e");
    }
  }


  void _removePhoto() {
    print('_removePhoto called...........');
    setState(() {
      _photoBytes = null;
      _photoRemoved = true;
      //_photoUrl = null;
    });
  }

  void _showPhotoPopup(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.memory(bytes),
          ),
        ),
      ),
    );
  }



  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    const uuid = Uuid();
    final String studentId = widget.student?.id ?? uuid.v4();
    final String studentStatus = widget.student?.status ?? 'notsent';

    // final SupabaseClient client = SupabaseService.client;
    // final session = client.auth.currentSession;
    // final String franId = session?.user?.userMetadata?['franchise_id'] ?? ""; //todo: have to add a dropdown for superadmin to select franchise
    // final String franchiseId = widget.student?.franchiseId ?? franId;


    // --- PHOTO HANDLING BEFORE SAVE ---
    String? newPhotoUrl = _photoUrl;

// user picked new image
    if (_photoBytes != null) {
      newPhotoUrl = await SupabaseService.uploadStudentPhoto(
        studentId: studentId,
        bytes: _photoBytes!,
      );
    }

// user removed existing image
    if (_photoRemoved && _photoUrl != null && _photoUrl!.isNotEmpty) {
      await SupabaseService.deleteStudentPhoto(_photoUrl!);
      newPhotoUrl = null;
      _photoUrl = null;
    }


    try {

      final provider = Provider.of<StudentProvider>(context, listen: false);

      final student = Student(
        id: studentId,
        status: studentStatus,
        franchiseId: _selectedFranchiseId!,
        photoUrl: newPhotoUrl,

        name: _nameController.text.trim(),
        dob: _dobController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(_dobController.text)
            : null,
        gender: _genderController.text.trim().isNotEmpty ? _genderController.text.trim() : null,
        aadharNumber: _aadharController.text.trim().isNotEmpty ? _aadharController.text.trim() : null,
        motherTongue: _motherTongueController.text.trim().isNotEmpty ? _motherTongueController.text.trim() : null,
        fatherName: _fatherNameController.text.trim().isNotEmpty ? _fatherNameController.text.trim() : null,
        motherName: _motherNameController.text.trim().isNotEmpty ? _motherNameController.text.trim() : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        phoneNumber2: _phone2Controller.text.trim().isNotEmpty ? _phone2Controller.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        pincode: _pincodeController.text.trim().isNotEmpty ? _pincodeController.text.trim() : null,
        district: _districtController.text.trim().isNotEmpty ? _districtController.text.trim() : null,
        admissionYearId: _selectedAcademicYearId!,
        admissionCode: _admissionCodeController.text.trim().isNotEmpty ? _admissionCodeController.text.trim() : null,
        refNoDate: _refNoDateController.text.isNotEmpty
            ? DateFormat('dd/MM/yyyy').parse(_refNoDateController.text)
            : null,
        classId: _selectedClassId!,
        rollNumber: _rollNumberController.text.trim(),
        createdAt: widget.student?.createdAt ?? DateTime.now(),
      );

      if (widget.student == null) {
        await provider.addStudent(student);
        _showSuccess('Student added successfully!');
      } else {
        await provider.updateStudent(student);
        _showSuccess('Student updated successfully!');
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save student: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
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
    bottomNavIndex.value = 1;

    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: CustomAppBar(
        title: widget.student == null ? 'Add Student' : 'Edit Student',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () async {

                    final stprovider = context.read<StudentProvider>();

                    List<Class> classes= stprovider.classes;

                    final Map<String, String> classMap = {
                      for (final c in classes) c.id: c.name,
                    };
                    final className = classMap[_selectedClassId] ?? '';


                    await StudentPdfService.downloadStudentForm(
                      data: {
                        'name': _nameController.text,
                        'dob': _dobController.text,
                        'gender': _genderController.text,
                        'aadhar': _aadharController.text,
                        'motherTongue': _motherTongueController.text,

                        'father': _fatherNameController.text,
                        'mother': _motherNameController.text,

                        'phone': _phoneController.text,
                        'phone2': _phone2Controller.text,
                        'email': _emailController.text,

                        'address': _addressController.text,
                        'district': _districtController.text,
                        'pincode': _pincodeController.text,

                        'year': _selectedAcademicYearId,
                        'class': className,
                        'roll': _rollNumberController.text,
                        'admissionCode': _admissionCodeController.text,
                      },
                    );
                  },
                ),

                IconButton(onPressed: _isLoading ? null : _saveStudent, icon: const Icon(Icons.save)),
              ],
            ),
          )
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingIndicator(message: 'Saving student...');
          }

          return _buildForm(context, provider);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, StudentProvider provider) {
    return Form(
      key: _formKey,
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(
            ResponsiveUtils.responsiveValue(context, 16.0, 20.0, 24.0),
          ),
          child: Column(
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              //Text(widget.student!.id.toString()),

              // PHOTO SECTION
              //_buildPhotoSection(),
              const SizedBox(height: 24),

              _buildPersonalInfoSection(),

              const SizedBox(height: 24),

              // Parent Information Section
              _buildSectionHeader('Parent Information'),
              _buildParentInfoSection(),

              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              _buildContactInfoSection(),

              const SizedBox(height: 24),

              // Address Information Section
              _buildSectionHeader('Address Information'),
              _buildAddressInfoSection(),

              const SizedBox(height: 24),

              // Academic Information Section
              _buildSectionHeader('Academic Information'),
              _buildAcademicInfoSection(context, provider),

              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


// network popup loader

  Widget _buildPhotoSection() {
    final size = MediaQuery.of(context).size;

    // Responsive sizes
    double photoWidth = size.width < 600
        ? 120
        : size.width < 1100
        ? 150
        : 180;

    double photoHeight = photoWidth * 1.2;

    double buttonFontSize = size.width < 600 ? 13 : 15;
    double buttonPadding = size.width < 600 ? 10 : 14;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // PHOTO CONTAINER
            GestureDetector(
              onTap: () {
                if (_photoBytes != null) {
                  _showPhotoPopup(_photoBytes!);
                } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
                  _openNetworkPhoto(_photoUrl!);
                }
              },
              child: Container(
                width: photoWidth,
                height: photoHeight,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                  image: _photoBytes != null
                      ? DecorationImage(
                    image: MemoryImage(_photoBytes!),
                    fit: BoxFit.cover,
                  )
                      : (!_photoRemoved &&
                      _photoUrl != null &&
                      _photoUrl!.isNotEmpty)
                      ? DecorationImage(
                    image: NetworkImage(
                      "${SupabaseService.client.storage
                          .from('student-photos')
                          .getPublicUrl(_photoUrl!)}?v=${DateTime.now().millisecondsSinceEpoch}",
                    ),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: (_photoBytes == null &&
                    (_photoUrl == null ||
                        _photoUrl!.isEmpty ||
                        _photoRemoved))
                    ? const Icon(Icons.person,
                    size: 60, color: Colors.white)
                    : null,
              ),
            ),

            // TOP-RIGHT DELETE (X) BUTTON
            if (_photoBytes != null ||
                (_photoUrl != null && _photoUrl!.isNotEmpty))
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: _removePhoto,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_forever,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // RESPONSIVE UPLOAD/CHANGE BUTTON
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: buttonPadding),
            textStyle: TextStyle(fontSize: buttonFontSize),
          ),
          onPressed: _pickPhoto,
          child: Text(
            _photoBytes == null && (_photoUrl == null || _photoUrl!.isEmpty)
                ? "Upload"
                : "Change",
          ),
        ),
      ],
    );
  }

  void _openNetworkPhoto(String path) async {
    try {
      final url = "${SupabaseService.client.storage
          .from('student-photos')
          .getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}";

      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        _showPhotoPopup(resp.bodyBytes);
      }
    } catch (_) {}
  }





  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter student name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 11),
                    CustomTextField(
                      controller: _motherTongueController,
                      label: 'Mother Tongue',
                    ),
                  ],
                ),
              ),
            ),
            _buildPhotoSection(),

          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _dobController,
                label: 'Date of Birth',
                readOnly: true,
                onTap: () => _selectDate(_dobController),
                suffixIcon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ResponsiveDropdown<String?>(
                label: 'Gender',
                value: _genderController.text.isNotEmpty
                    ? _genderController.text
                    : null,
                hint: '',
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Others', child: Text('Others')),
                ],
                onChanged: (value) {
                  setState(() {
                    _genderController.text = value ?? '';
                  });
                },
              ),
            ),


          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [

            Expanded(
              child: CustomTextField(
                controller: _aadharController,
                label: 'Aadhar Number',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParentInfoSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _fatherNameController,
          label: 'Father\'s Name',
        ),
        const SizedBox(height: 11),
        CustomTextField(
          controller: _motherNameController,
          label: 'Mother\'s Name',
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 11),
        CustomTextField(
          controller: _phone2Controller,
          label: 'Alternate Phone Number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 11),
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildAddressInfoSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _addressController,
          label: 'Address',
          maxLines: 3,
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _pincodeController,
                label: 'Pincode',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [

            Expanded(
              child: CustomTextField(
                controller: _districtController,
                label: 'District',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicInfoSection(BuildContext context, StudentProvider provider) {
    return Column(
      children: [
        // Academic Year Dropdown
        ResponsiveDropdown<String?>(
          label: 'Academic Year *',
          value: _selectedAcademicYearId,
          items: provider.academicYears.map((year) {
            return DropdownMenuItem<String?>(
              value: year.id,
              child: Text('${year.year} ${year.isActive ? '(Active)' : ''}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedAcademicYearId = value);
          },
          validator: (value) {
            if (value == null) return 'Please select academic year';
            return null;
          },
          hint: 'Select Academic Year',
        ),
        const SizedBox(height: 11),

        // Class Dropdown
        ResponsiveDropdown<String?>(
          label: 'Course *',
          value: _selectedClassId,
          items: provider.classes.map((classItem) {
            return DropdownMenuItem<String?>(
              value: classItem.id,
              child: Text(classItem.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClassId = value;
            });
          },
          validator: (value) {
            if (value == null) return 'Please select course';
            return null;
          },
          hint: 'Select Course',
        ),
        const SizedBox(height: 11),

        //if (Supabase.instance.client.auth.currentUser?.userMetadata?['role'] == "superadmin")

          ResponsiveDropdown<String?>(
          label: 'Franchise *',
          value: _selectedFranchiseId,
          items: provider.franchises.map((franchiseItem) {
            return DropdownMenuItem<String?>(
              value: franchiseItem.id,
              child: Text(franchiseItem.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFranchiseId = value;
            });
          },
          validator: (value) {
            if (value == null) return 'Please franchise';
            return null;
          },
          hint: 'Select franchise',
        ),
        const SizedBox(height: 11),

        // Section Dropdown (only if class is selected)

        // Roll Number
        CustomTextField(
          controller: _rollNumberController,
          label: 'Roll Number *',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter roll number';
            }
            return null;
          },
        ),
        const SizedBox(height: 11),

        // Admission Code and Reference Date
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _admissionCodeController,
                label: 'Admission Code',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _refNoDateController,
                label: 'Reference Date',
                readOnly: true,
                onTap: () => _selectDate(_refNoDateController),
                suffixIcon: Icons.calendar_today,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return AdaptiveButton(
      onPressed: _isLoading ? null : _saveStudent,
      text: _isLoading
          ? 'Saving...'
          : widget.student == null ? 'Add Student' : 'Update Student',
      fullWidth: true,
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _aadharController.dispose();
    _motherTongueController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _districtController.dispose();
    _admissionCodeController.dispose();
    _refNoDateController.dispose();
    _rollNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
import 'package:brainwavers/widgets/common/adaptive_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../providers/academic_data_provider.dart';
import '../../providers/marks_provider.dart';
import '../../models/mark_model.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/student_provider.dart';

class SingleStudentMarksScreen extends StatefulWidget {
  final Student student;
  final String academicYearId;
  final int term;
  final VoidCallback onPressedFinalSendReq;


  const SingleStudentMarksScreen({
    super.key,
    required this.student,
    required this.academicYearId,
    required this.term,
    required this.onPressedFinalSendReq,
  });

  @override
  _SingleStudentMarksScreenState createState() =>
      _SingleStudentMarksScreenState();
}

class _SingleStudentMarksScreenState extends State<SingleStudentMarksScreen> {
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, bool> _absentStatus = {};

  bool _isLoading = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _loadInitialData();
  //   _initializeControllers();
  //   _loadExistingMarks();
  // }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);

    await _loadInitialData();
    _initializeControllers();
    await _loadExistingMarks();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _loadInitialData() async {
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final marksProvider = Provider.of<MarksProvider>(context, listen: false);

    await academicProvider.loadAcademicData();
    await studentProvider.loadInitialData();
    await marksProvider.loadMarks(); // Load all marks initially
  }

  List<Subject> _getSubjectsForClass() {
    final academicProvider = Provider.of<AcademicDataProvider>(context, listen: false);

    return academicProvider.getSubjectsForClass(widget.student.classId);
  }

  void _initializeControllers() {

    final subjects = _getSubjectsForClass();

     print(subjects);

    for (final subject in subjects) {
      _marksControllers[subject.id] = TextEditingController();
      _absentStatus[subject.id] = false;
    }
  }

  Future<void> _loadExistingMarks() async {
    setState(() {
      _isLoading = true;
    });

    final marksProvider = Provider.of<MarksProvider>(context, listen: false);
    final studentId = widget.student.id;
    final academicYearId = widget.academicYearId;
    final term = widget.term;

    try {
      final existingMarks = await marksProvider.getStudentMarks(
        studentId: studentId,
        academicYearId: academicYearId,
        term: term,
      );

      for (final mark in existingMarks) {
        final subjectId = mark.subjectId;
        if (_marksControllers.containsKey(subjectId)) {
          _marksControllers[subjectId]!.text = mark.isAbsent
              ? ""
              : mark.marksObtained.toString();
          _absentStatus[subjectId] = mark.isAbsent;
        }
      }
    } catch (e) {
      // Handle error if fetching marks failed
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveMarks() async {
    setState(() {
      _isLoading = true;
    });

    final marksProvider = Provider.of<MarksProvider>(context, listen: false);
    final studentId = widget.student.id;
    final academicYearId = widget.academicYearId;
    final term = widget.term;

    int savedCount = 0;
    int errorCount = 0;

    final academicProvider =
    Provider.of<AcademicDataProvider>(context, listen: false);
    final subjects = academicProvider.getSubjectsForClass(widget.student.classId);

    for (final subject in subjects) {
      final controller = _marksControllers[subject.id];
      final isAbsent = _absentStatus[subject.id] ?? false;

      // Skip if no marks entered and not absent
      if ((controller?.text.isEmpty ?? true) && !isAbsent) {
        continue;
      }

      int marksObtained = 0;
      if (!isAbsent) {
        marksObtained = int.tryParse(controller?.text ?? '0') ?? 0;

        // Validate marks
        if (marksObtained > subject.totalMarks) {
          _showError('Marks for ${widget.student.name} in ${subject.name} cannot exceed ${subject.totalMarks}');
          errorCount++;
          continue;
        }
      }

      final mark = Mark(
        id: const Uuid().v4(),
        franchiseId: widget.student.franchiseId ,
        studentId: studentId,
        subjectId: subject.id,
        academicYearId: academicYearId,
        term: term,
        marksObtained: marksObtained,
        isAbsent: isAbsent,
        createdAt: DateTime.now(),
      );

      try {
        await marksProvider.saveMark(mark);
        savedCount++;
      } catch (e) {
        errorCount++;
        print('Error saving mark for ${widget.student.name}: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });

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
      appBar: AppBar(
        title: Text('Enter Marks for ${widget.student.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: _buildSubjectInputFields(),
                      ),
                    ),
                    Row(
                      children: [
                        AdaptiveButton(
                            onPressed: _saveMarks,
                            text: "Save Marks"
                        ),
                        const Spacer(),
                        AdaptiveButton(
                            onPressed: widget.onPressedFinalSendReq,
                            text: "Send Req"
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubjectInputFields() {
    final academicProvider =
    Provider.of<AcademicDataProvider>(context, listen: false);
    final subjects = academicProvider.getSubjectsForClass(widget.student.classId);

    return subjects.map((subject) {
      final controller = _marksControllers[subject.id];
      final isAbsent = _absentStatus[subject.id] ?? false;

      return ListTile(
        title: Text(subject.name),
        subtitle: Text('Total Marks: ${subject.totalMarks}'),
        trailing: Checkbox(
          value: isAbsent,
          onChanged: (value) {
            setState(() {
              _absentStatus[subject.id] = value ?? false;
              if (value == true) controller?.clear();
            });
          },
        ),
        leading: SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            enabled: !isAbsent,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0-${subject.totalMarks}',
            ),
          ),
        ),
      );
    }).toList();
  }
}

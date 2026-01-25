import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/result_model.dart';
import '../../models/student_model.dart';

class MarksheetPdfServiceBetter {
  static Future<Uint8List> generateBulk({
    required List<StudentResult> results,
    required int term, // 1,2,3
    required String schoolName,
  }) async {
    final pdf = pw.Document();

    // 🔥 LOAD THE SAME FONT YOU USE IN UI
    final appFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Lexend-Regular.ttf'),
    );

    // 🔥 APPLY FONT GLOBALLY
    final theme = pw.ThemeData.withFont(
      base: appFont,
      bold: appFont,
    );

    for (final result in results) {
      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => [
            _buildHeader(schoolName, term),
            pw.SizedBox(height: 8),
            _studentDetails(result.student),
            pw.SizedBox(height: 12),
            _upperTables(result, term),
            pw.SizedBox(height: 12),
            _academicTable(result, term),
            pw.SizedBox(height: 12),
            _remarksAndSignature(),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // ---------------- HEADER ----------------

  static pw.Widget _buildHeader(String schoolName, int term) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Container(
            height: 40,
            width: 40,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Center(child: pw.Text('LOGO')),
          ),
          pw.Column(
            children: [
              pw.Text(
                schoolName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('ACADEMIC REPORT'),
            ],
          ),
          pw.Text(
            'TERM $term',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ---------------- STUDENT DETAILS ----------------

  static pw.Widget _studentDetails(Student student) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'STUDENT DETAILS',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Name: ${student.name}'),
              pw.Text('Roll: ${student.rollNumber}'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Class: ${student.classId}'),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- UPPER TABLES ----------------

  static pw.Widget _upperTables(StudentResult result, int term) {
    final personalitySubjects = result.subjectResults.values
        .where((s) => s.subject.orderIndex == 2)
        .toList();

    final coCurricularSubjects = result.subjectResults.values
        .where((s) => s.subject.orderIndex == 3)
        .toList();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _gradeMarksTable(
            'CULTIVATE OF PERSONALITY',
            personalitySubjects,
            term,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _gradeMarksTable(
            'CO-CURRICULAR SUBJECTS',
            coCurricularSubjects,
            term,
          ),
        ),
      ],
    );
  }

  static pw.Widget _gradeMarksTable(
      String title,
      List<SubjectResult> subjects,
      int term,
      ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                title,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(child: pw.Text('Marks')),
            pw.Center(child: pw.Text('Grade')),
          ],
        ),
        ...subjects.map((sr) {
          final marks = _marksForTerm(sr, term);

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(sr.subject.name),
              ),
              pw.Center(
                child: pw.Text(sr.isAbsent ? '-' : '$marks'),
              ),
              pw.Center(child: pw.Text(sr.isAbsent ? 'AB' : sr.grade)),
            ],
          );
        }),
      ],
    );
  }

  // ---------------- ACADEMIC TABLE ----------------

  static pw.Widget _academicTable(StudentResult result, int term) {
    final academicSubjects = result.subjectResults.values
        .where((s) => s.subject.orderIndex == 1)
        .toList();

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        if (term == 3) 5: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Text('Subject', textAlign: pw.TextAlign.center),
            pw.Text('Full', textAlign: pw.TextAlign.center),
            pw.Text('Obtained', textAlign: pw.TextAlign.center),
            pw.Text('Grade', textAlign: pw.TextAlign.center),
            pw.Text('%', textAlign: pw.TextAlign.center),
            if (term == 3)
              pw.Text('Yearly Total', textAlign: pw.TextAlign.center),
          ],
        ),
        ...academicSubjects.map((sr) {
          final obtained = _marksForTerm(sr, term);

          return pw.TableRow(
            children: [
              pw.Text(sr.subject.name),
              pw.Text(
                '${sr.subject.totalMarks}',
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                sr.isAbsent ? '-' : '$obtained',
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(sr.isAbsent ? 'AB' : sr.grade,
                  textAlign: pw.TextAlign.center),
              pw.Text(
                sr.percentage.toStringAsFixed(1),
                textAlign: pw.TextAlign.center,
              ),
              if (term == 3)
                pw.Text(
                  sr.yearlyTotal?.toString() ?? '-',
                  textAlign: pw.TextAlign.center,
                ),
            ],
          );
        }),
        _totalRow(result, term),
      ],
    );
  }

  static pw.TableRow _totalRow(StudentResult result, int term) {
    final tr = result.termResult;

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('${tr.totalMaxMarks}', textAlign: pw.TextAlign.center),
        pw.Text('${tr.totalMarksObtained}',
            textAlign: pw.TextAlign.center),
        pw.Text(tr.grade, textAlign: pw.TextAlign.center),
        pw.Text(tr.percentage.toStringAsFixed(1),
            textAlign: pw.TextAlign.center),
        if (term == 3) pw.Text('-', textAlign: pw.TextAlign.center),
      ],
    );
  }

  // ---------------- HELPERS ----------------

  static int _marksForTerm(SubjectResult sr, int term) {
    if (sr.isAbsent) return 0;
    return sr.totalMarks;
  }


  // ---------------- FOOTER ----------------

  static pw.Widget _remarksAndSignature() {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('REMARKS:'),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Container(
          width: 120,
          height: 60,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Center(child: pw.Text('HEAD SIGN')),
        ),
      ],
    );
  }
}

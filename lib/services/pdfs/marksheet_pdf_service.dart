import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/mark_model.dart';
import '../../models/result_model.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';
import '../../utils/grade_calculator.dart';


class MarksheetPdfService {
  static Future<Uint8List> generateBulk({
    required List<Student> students,
    required List<Subject> subjects,
    required List<Mark> marks,
    required int term, // 1,2,3
    required String schoolName,
  }) async {
    final pdf = pw.Document();

    for (final student in students) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (_) => [
            _buildHeader(schoolName, term),
            pw.SizedBox(height: 8),
            _studentDetails(student),
            pw.SizedBox(height: 12),
            _upperTables(student, subjects, marks, term),
            pw.SizedBox(height: 12),
            _academicTable(student, subjects, marks, term),
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
          pw.Text('STUDENT DETAILS',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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

  // ---------------- UPPER TABLES (ORDER 2 & 3) ----------------

  static pw.Widget _upperTables(
      Student student,
      List<Subject> subjects,
      List<Mark> marks,
      int term,
      ) {
    final personalitySubjects =
    subjects.where((s) => s.orderIndex == 2).toList();
    final coCurricularSubjects =
    subjects.where((s) => s.orderIndex == 3).toList();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _gradeMarksTable(
            'CULTIVATE OF PERSONALITY',
            personalitySubjects,
            student,
            marks,
            term,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _gradeMarksTable(
            'CO-CURRICULAR SUBJECTS',
            coCurricularSubjects,
            student,
            marks,
            term,
          ),
        ),
      ],
    );
  }

  static pw.Widget _gradeMarksTable(
      String title,
      List<Subject> subjects,
      Student student,
      List<Mark> marks,
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
              child: pw.Text(title,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(child: pw.Text('Marks')),
            pw.Center(child: pw.Text('Grade')),
          ],
        ),
        ...subjects.map((sub) {
          final mark = marks.firstWhere(
                (m) =>
            m.studentId == student.id &&
                m.subjectId == sub.id &&
                m.term == term,
            orElse: () => Mark(
              franchiseId: '',
              id: '',
              studentId: student.id,
              subjectId: sub.id,
              academicYearId: '',
              term: term,
              marksObtained: 0,
              isAbsent: true,
              createdAt: DateTime.now(),
            ),
          );

          final grade = mark.isAbsent
              ? 'AB'
              : GradeUtils.gradeFromMarks(
              mark.marksObtained, sub.totalMarks);

          return pw.TableRow(
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(sub.name)),
              pw.Center(
                  child: pw.Text(
                      mark.isAbsent ? '-' : '${mark.marksObtained}')),
              pw.Center(child: pw.Text(grade)),
            ],
          );
        }),
      ],
    );
  }

  // ---------------- ACADEMIC TABLE ----------------

  static pw.Widget _academicTable(
      Student student,
      List<Subject> subjects,
      List<Mark> marks,
      int term,
      ) {
    final academicSubjects =
    subjects.where((s) => s.orderIndex == 1).toList();

    int totalFull = 0;
    int totalObtained = 0;

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
        ...academicSubjects.map((sub) {
          final termMarks = marks.where((m) =>
          m.studentId == student.id &&
              m.subjectId == sub.id &&
              m.term == term);

          final mark = termMarks.isNotEmpty ? termMarks.first : null;

          final obtained = mark?.marksObtained ?? 0;
          totalFull += sub.totalMarks;
          totalObtained += obtained;

          final percent =
          sub.totalMarks == 0 ? 0 : (obtained / sub.totalMarks) * 100;

          final yearlyTotal = term == 3
              ? marks
              .where((m) =>
          m.studentId == student.id &&
              m.subjectId == sub.id)
              .fold<int>(0, (s, m) => s + m.marksObtained)
              : null;

          return pw.TableRow(
            children: [
              pw.Text(sub.name),
              pw.Text('${sub.totalMarks}',
                  textAlign: pw.TextAlign.center),
              pw.Text('$obtained', textAlign: pw.TextAlign.center),
              pw.Text(
                GradeUtils.gradeFromMarks(obtained, sub.totalMarks),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(percent.toStringAsFixed(1),
                  textAlign: pw.TextAlign.center),
              if (term == 3)
                pw.Text('$yearlyTotal',
                    textAlign: pw.TextAlign.center),
            ],
          );
        }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Text('TOTAL',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('$totalFull', textAlign: pw.TextAlign.center),
            pw.Text('$totalObtained', textAlign: pw.TextAlign.center),
            pw.Text(
              GradeUtils.gradeFromMarks(totalObtained, totalFull),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              totalFull == 0
                  ? '0'
                  : ((totalObtained / totalFull) * 100)
                  .toStringAsFixed(1),
              textAlign: pw.TextAlign.center,
            ),
            if (term == 3) pw.Text('-', textAlign: pw.TextAlign.center),
          ],
        ),
      ],
    );
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



// PDF Service
// -----------------------------
// class MarksheetPdfService {
//   // -------------------- Single Student --------------------
//   static Future<Uint8List> generateSingle({
//     required StudentResult studentResult,
//     required int term,
//     required String schoolName,
//     Uint8List? schoolLogoBytes,
//   }) async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.Page(
//         build: (_) => _buildMarksheetPage(
//           studentResult: studentResult,
//           term: term,
//           schoolName: schoolName,
//           schoolLogoBytes: schoolLogoBytes,
//         ),
//       ),
//     );
//
//     return pdf.save();
//   }
//
//   // -------------------- Bulk PDF --------------------
//   static Future<Uint8List> generateBulk({
//     required List<StudentResult> studentResults,
//     required int term,
//     required String schoolName,
//     Uint8List? schoolLogoBytes,
//   }) async {
//     final pdf = pw.Document();
//
//     for (final sr in studentResults) {
//       pdf.addPage(
//         pw.Page(
//           build: (_) => _buildMarksheetPage(
//             studentResult: sr,
//             term: term,
//             schoolName: schoolName,
//             schoolLogoBytes: schoolLogoBytes,
//           ),
//         ),
//       );
//     }
//
//     return pdf.save();
//   }
//
//   // -------------------- Build Page --------------------
//   static pw.Widget _buildMarksheetPage({
//     required StudentResult studentResult,
//     required int term,
//     required String schoolName,
//     Uint8List? schoolLogoBytes,
//   }) {
//     // Split subjects by orderIndex
//     final personalitySubjects = studentResult.subjectResults.values
//         .where((sr) => sr.subject.orderIndex == 2)
//         .toList();
//     final cocurricularSubjects = studentResult.subjectResults.values
//         .where((sr) => sr.subject.orderIndex == 3)
//         .toList();
//     final academicSubjects = studentResult.subjectResults.values
//         .where((sr) => sr.subject.orderIndex == 1)
//         .toList();
//
//     return pw.Padding(
//       padding: const pw.EdgeInsets.all(12),
//       child: pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           // -------- Header --------
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               if (schoolLogoBytes != null)
//                 pw.Image(pw.MemoryImage(schoolLogoBytes), width: 50, height: 50)
//               else
//                 pw.Container(width: 50, height: 50, color: PdfColors.grey300),
//               pw.Column(
//                 children: [
//                   pw.Text(schoolName,
//                       style: pw.TextStyle(
//                           fontSize: 18, fontWeight: pw.FontWeight.bold)),
//                   pw.Text('Term $term Marksheet',
//                       style: const pw.TextStyle(fontSize: 14)),
//                 ],
//               ),
//               pw.SizedBox(width: 50),
//             ],
//           ),
//           pw.Divider(),
//
//           // -------- Student Details --------
//           pw.Padding(
//             padding: const pw.EdgeInsets.symmetric(vertical: 6),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text('Name: ${studentResult.student.name}'),
//                 pw.Text('Roll No: ${studentResult.student.rollNumber}'),
//                 pw.Text('Admission Code: ${studentResult.student.admissionCode ?? ''}'),
//                 pw.Text('Class / Section: ${studentResult.student.classId} / ${studentResult.student.sectionId}'),
//               ],
//             ),
//           ),
//           pw.SizedBox(height: 12),
//
//           // -------- Top Tables --------
//           pw.Row(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Personality
//               pw.Expanded(
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text('CULTIVATE OF PERSONALITY',
//                         style:  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                     pw.Table.fromTextArray(
//                       headers: ['Trait', 'Marks / Grade'],
//                       data: personalitySubjects.map((sr) {
//                         final marks = _getMarks(sr, term);
//                         final grade = _getGrade(sr, term);
//                         return [sr.subject.name, '$marks / $grade'];
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               pw.SizedBox(width: 12),
//               // Co-curricular
//               pw.Expanded(
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text('CO-CURRICULAR SUBJECTS',
//                         style:  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                     pw.Table.fromTextArray(
//                       headers: ['Activity', 'Marks / Grade'],
//                       data: cocurricularSubjects.map((sr) {
//                         final marks = _getMarks(sr, term);
//                         final grade = _getGrade(sr, term);
//                         return [sr.subject.name, '$marks / $grade'];
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           pw.SizedBox(height: 12),
//
//           // -------- Academic --------
//           pw.Text('ACADEMIC SUBJECTS',
//               style:  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//           pw.Table.fromTextArray(
//             headers: term == 3
//                 ? ['Subject', 'Full Marks', 'Marks Obtained', 'Yearly Total']
//                 : ['Subject', 'Full Marks', 'Marks Obtained'],
//             data: academicSubjects.map((sr) {
//               final marks = _getMarks(sr, term);
//               final yearlyTotal = (sr.term1Marks ?? 0) +
//                   (sr.term2Marks ?? 0) +
//                   (sr.term3Marks ?? 0);
//               return term == 3
//                   ? [
//                 sr.subject.name,
//                 sr.subject.totalMarks.toString(),
//                 marks.toString(),
//                 yearlyTotal.toString()
//               ]
//                   : [
//                 sr.subject.name,
//                 sr.subject.totalMarks.toString(),
//                 marks.toString(),
//               ];
//             }).toList(),
//           ),
//           pw.SizedBox(height: 12),
//
//           // -------- Remarks --------
//           pw.Text('Remarks:', style:  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//           pw.Container(height: 50, color: PdfColors.grey200),
//           pw.SizedBox(height: 24),
//
//           // -------- Head Signature --------
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.end,
//             children: [
//               pw.Column(
//                 children: [
//                   pw.Container(width: 120, height: 1, color: PdfColors.black),
//                   pw.Text('Head of School'),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // -------------------- Helpers --------------------
//   static int _getMarks(SubjectResult sr, int term) {
//     switch (term) {
//       case 1:
//         return sr.term1Marks ?? 0;
//       case 2:
//         return sr.term2Marks ?? 0;
//       case 3:
//         return sr.term3Marks ?? 0;
//       default:
//         return 0;
//     }
//   }
//
//   static String _getGrade(SubjectResult sr, int term) {
//     final marks = _getMarks(sr, term);
//     final total = sr.subject.totalMarks;
//     final percent = total == 0 ? 0 : (marks / total) * 100;
//
//     if (percent >= 90) return 'A+';
//     if (percent >= 80) return 'A';
//     if (percent >= 70) return 'B+';
//     if (percent >= 60) return 'B';
//     if (percent >= 50) return 'C';
//     return 'D';
//   }
// }




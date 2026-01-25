import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/result_model.dart';
import '../../models/student_model.dart';

class MarksheetPdfServiceLandscape {
  static const double _halfWidth = 397;
  static const double _innerPadding = 10;

  static Future<Uint8List> generateBulk({
    required List<StudentResult> results,
    required int term,
    required String schoolName,
  }) async {
    final pdf = pw.Document();

    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Lexend-Regular.ttf'),
    );

    final theme = pw.ThemeData.withFont(base: font, bold: font);

    for (final result in results) {
      pdf.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (_) {
            return pw.Column(
              children: [
                _header(schoolName, result.student, term),
                pw.SizedBox(height: 12),

                /// BODY (EXACT HALF SPLIT)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: _halfWidth,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(
                          left: _innerPadding,
                          right: _innerPadding,
                        ),
                        child: _leftSide(result),
                      ),
                    ),

                    pw.Container(
                      width: 1,
                      color: PdfColors.grey500,
                    ),

                    pw.SizedBox(
                      width: _halfWidth,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(
                          left: _innerPadding,
                          right: _innerPadding,
                        ),
                        child: term == 4
                            ? _yearlyAcademicTable(result)
                            : _termAcademicTable(result),
                      ),
                    ),
                  ],
                ),


                pw.SizedBox(height: 12),
                _footer(),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // ================= helpers =========================
  static String _gradeFromPercentage(double p) {
    if (p >= 80) return 'A+';
    if (p >= 60) return 'A';
    if (p >= 40) return 'B';
    return 'C';
  }

  static TermResult _academicTermResult(
      List<SubjectResult> academicSubjects,
      ) {
    // FULL MARKS → ALL academic subjects
    final totalFull = academicSubjects.fold<int>(
      0,
          (sum, s) => sum + s.subject.totalMarks,
    );

    // OBTAINED → only non-absent subjects
    final totalObtained = academicSubjects
        .where((s) => !s.isAbsent)
        .fold<int>(0, (sum, s) => sum + s.totalMarks);

    final percentage =
    totalFull == 0 ? 0 : (totalObtained / totalFull) * 100;

    return TermResult(
      totalMarksObtained: totalObtained,
      totalMaxMarks: totalFull,
      percentage: percentage.toDouble(),
      grade: _gradeFromPercentage(percentage.toDouble()),
    );
  }


  static TermResult _academicYearlyResult(
      List<SubjectResult> academicSubjects,
      ) {
    // FULL MARKS → ALL academic subjects × 3 terms
    final totalFull = academicSubjects.fold<int>(
      0,
          (sum, s) => sum + (s.subject.totalMarks * 3),
    );

    // OBTAINED → only subjects with yearlyTotal
    final totalObtained = academicSubjects
        .where((s) => s.yearlyTotal != null)
        .fold<int>(0, (sum, s) => sum + s.yearlyTotal!);

    final percentage =
    totalFull == 0 ? 0 : (totalObtained / totalFull) * 100;

    return TermResult(
      totalMarksObtained: totalObtained,
      totalMaxMarks: totalFull,
      percentage: percentage.toDouble(),
      grade: _gradeFromPercentage(percentage.toDouble()),
    );
  }


  static Map<String, int> _termWiseTotals(
      List<SubjectResult> academicSubjects,
      ) {
    int t1 = 0;
    int t2 = 0;
    int t3 = 0;
    int full = 0;
    int yearly = 0;

    for (final s in academicSubjects) {
      full += s.subject.totalMarks;

      if (s.term1Marks != null) t1 += s.term1Marks!;
      if (s.term2Marks != null) t2 += s.term2Marks!;
      if (s.term3Marks != null) t3 += s.term3Marks!;
      if (s.yearlyTotal != null) yearly += s.yearlyTotal!;
    }

    return {
      'full': full * 3,
      't1': t1,
      't2': t2,
      't3': t3,
      'yearly': yearly,
    };
  }





  // ================= HEADER =================

  static pw.Widget _header(
      String schoolName,
      Student student,
      int term,
      ) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          schoolName.toUpperCase(),
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),

        pw.Row(
          children: [
            pw.SizedBox(
              width: _halfWidth,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: _innerPadding),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Name: ${student.name}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Roll: ${student.rollNumber}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ),

            pw.Container(width: 1, height: 18, color: PdfColors.grey500),

            pw.SizedBox(
              width: _halfWidth,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: _innerPadding),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  term == 4 ? 'FINAL RESULT' : 'TERM $term' ,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ),
          ],
        ),

        pw.Divider(thickness: 1),
      ],
    );
  }


  // ================= LEFT SIDE =================

  static pw.Widget _leftSide(StudentResult result) {
    final coCurricular = result.subjectResults.values
        .where((s) => s.subject.orderIndex == 3)
        .toList();

    final personality = result.subjectResults.values
        .where((s) => s.subject.orderIndex == 2)
        .toList();

    return pw.Column(
      children: [
        _leftGradeTable('CO-CURRICULAR SUBJECTS', coCurricular),
        pw.SizedBox(height: 12),
        _leftGradeTable('CULTIVATE OF PERSONALITY', personality),
      ],
    );
  }

  static pw.Widget _leftGradeTable(
      String title,
      List<SubjectResult> subjects,
      ) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          _sectionHeader(title),
          pw.Table(
            border: pw.TableBorder.symmetric(inside: const pw.BorderSide(width: .5)),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              _tableHeaderRow(['Subject', 'Grade']),
              ...subjects.map(
                    (sr) => pw.TableRow(
                  children: [
                    _cell(sr.subject.name),
                    _cell(sr.isAbsent ? 'AB' : sr.grade, center: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= RIGHT SIDE (TERM 1 & 2) =================

  static pw.Widget _termAcademicTable(StudentResult result) {
    final academic = result.subjectResults.values
        .where((s) => s.subject.orderIndex == 1)
        .toList();

    final academicTotal = _academicTermResult(academic);


    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          _sectionHeader('ACADEMIC PERFORMANCE'),
          pw.Table(
            border: pw.TableBorder.symmetric(inside: const pw.BorderSide(width: .5)),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              _tableHeaderRow(['Subject', 'Full', 'Obtained', '%', 'Grade']),
              ...academic.map((sr) {
                return pw.TableRow(
                  children: [
                    _cell(sr.subject.name),
                    _cell('${sr.subject.totalMarks}', center: true),
                    _cell(sr.isAbsent ? '-' : '${sr.totalMarks}', center: true),
                    _cell(sr.isAbsent ? '-' : sr.percentage.toStringAsFixed(1), center: true),
                    _cell(sr.isAbsent ? 'AB' : sr.grade, center: true),
                  ],
                );
              }),

              /// TOTAL ROW
    //final academicTotal = _academicTermResult(academic);

    _totalRow(
    'Total',
    academicTotal.totalMaxMarks,
    academicTotal.totalMarksObtained,
    academicTotal.percentage,
    academicTotal.grade,
    ),

    ],
          ),
        ],
      ),
    );
  }

  // ================= RIGHT SIDE (TERM 3) =================

  static pw.Widget _yearlyAcademicTable(StudentResult result) {
    final academic = result.subjectResults.values
        .where((s) => s.subject.orderIndex == 1)
        .toList();

    // final yearly = result.yearlyResult!;
    // final academicYearly = _academicYearlyResult(academic);

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          _sectionHeader('YEARLY CONSOLIDATED RESULT'),
          pw.Table(
            border: pw.TableBorder.symmetric(inside: const pw.BorderSide(width: .5)),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.3),
              6: const pw.FlexColumnWidth(1),
              7: const pw.FlexColumnWidth(1),
            },
            children: [
              _tableHeaderRow([
                'Subject',
                'Yearly Full',
                '1st T',
                '2nd T',
                '3rd T',
                'Yearly',
                '%',
                'Grade',
              ]),
              ...academic.map((sr) {
                String termCell(int? m) =>
                    m == null ? '-' : '$m/${sr.subject.totalMarks}';

                return pw.TableRow(
                  children: [
                    _cell(sr.subject.name),
                    _cell('${sr.subject.totalMarks * 3}', center: true),
                    _cell(termCell(sr.term1Marks), center: true),
                    _cell(termCell(sr.term2Marks), center: true),
                    _cell(termCell(sr.term3Marks), center: true),
                    _cell(sr.yearlyTotal?.toString() ?? '-', center: true),
                    _cell(sr.percentage.toStringAsFixed(1), center: true),
                    _cell(sr.grade, center: true),
                  ],
                );
              }),

              /// TOTAL ROW


              _yearlyTotalRow(academic),


            ],
          ),
        ],
      ),
    );
  }

  // ================= TOTAL ROW =================

  static pw.TableRow _totalRow(
      String label,
      int full,
      int obtained,
      double percent,
      String grade,
      ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _cell(label, bold: true),
        _cell('$full', center: true, bold: true),
        _cell('$obtained', center: true, bold: true),
        _cell(percent.toStringAsFixed(1), center: true, bold: true),
        _cell(grade, center: true, bold: true),
      ],
    );
  }

  static pw.TableRow _yearlyTotalRow(
      List<SubjectResult> academicSubjects,
      ) {
    final totals = _termWiseTotals(academicSubjects);

    final yearlyPercentage = totals['full'] == 0
        ? 0
        : (totals['yearly']! / totals['full']!) * 100;

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _cell('Total', bold: true),

        _cell('${totals['full']}', center: true, bold: true),

        _cell('${totals['t1']}/${totals['full']! ~/ 3}',
            center: true, bold: true),

        _cell('${totals['t2']}/${totals['full']! ~/ 3}',
            center: true, bold: true),

        _cell('${totals['t3']}/${totals['full']! ~/ 3}',
            center: true, bold: true),

        _cell('${totals['yearly']}', center: true, bold: true),

        _cell(yearlyPercentage.toStringAsFixed(1),
            center: true, bold: true),

        _cell(_gradeFromPercentage(yearlyPercentage.toDouble()),
            center: true, bold: true),
      ],
    );
  }


  // ================= FOOTER =================

  static pw.Widget _footer() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // LEFT HALF — REMARKS
        pw.SizedBox(
          width: _halfWidth,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(_innerPadding),
            child: pw.Container(
              height: 60,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Text(
                'Remarks:',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ),
        ),

        // CENTER DIVIDER (EXACT FOLD)
        pw.Container(
          width: 1,
          height: 60,
          color: PdfColors.grey500,
        ),

        // RIGHT HALF — SIGNATURES
        pw.SizedBox(
          width: _halfWidth,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(_innerPadding),
            child: pw.Container(
              height: 60,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Class Teacher',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Divider(),
                  pw.Text(
                    'Head of Institution',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ================= HELPERS =================

  static pw.Widget _sectionHeader(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      color: PdfColors.grey300,
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: headers
          .map((h) => _cell(h, bold: true, center: true))
          .toList(),
    );
  }

  static pw.Widget _cell(
      String text, {
        bool bold = false,
        bool center = false,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: center
          ? pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
      )
          : pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}

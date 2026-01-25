import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class StudentPdfService {
  static Future<void> downloadStudentForm({
    required Map<String, String?> data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => _buildPage(data),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'student_admission_form.pdf',
    );
  }

  static pw.Widget _buildPage(Map<String, String?> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _schoolHeader(),

        pw.SizedBox(height: 10),

        _section('Personal Information', [
          _row('Student Name', data['name']),
          _row('Date of Birth', data['dob']),
          _row('Gender', data['gender']),
          _row('Blood Group', data['blood']),
          _row('Aadhar No.', data['aadhar']),
          _row('Mother Tongue', data['motherTongue']),
        ]),

        _section('Parent Information', [
          _row('Father Name', data['father']),
          _row('Mother Name', data['mother']),
          _row('Contact No.', data['phone']),
        ]),

        _section('Address', [
          _row('Village', data['address']),
          _row('Post Office', data['postOffice']),
          _row('Police Station', data['policeStation']),
          _row('District', data['district']),
          _row('Pincode', data['pincode']),
        ]),

        _section('Academic Details', [
          _row('Class', data['class']),
          _row('Section', data['section']),
          _row('Roll No.', data['roll']),
          _row('Admission Code', data['admissionCode']),
        ]),

        pw.SizedBox(height: 10),

        _fullCutLine(),

        pw.SizedBox(height: 6),

        _officialUseOnly(data),
      ],
    );
  }

  // ================= HEADER =================

  static pw.Widget _schoolHeader() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ABC PUBLIC SCHOOL',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Vill: Sample Village, Dist: South Dinajpur, PIN: 733000',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Phone: 9876543210',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
        pw.Container(
          width: 80,
          height: 95,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.7),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'Paste\nPhoto',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }

  // ================= SECTIONS =================

  static pw.Widget _section(String title, List<pw.Widget> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 5),
          color: PdfColors.grey300,
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        ...rows,
      ],
    );
  }

  static pw.Widget _row(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 135,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? '',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
  }

  // ================= OFFICIAL USE =================

  static pw.Widget _fullCutLine() {
    return pw.Container(
      width: double.infinity,
      child: pw.Divider(
        thickness: 0.8,
      ),
    );
  }

  static pw.Widget _officialUseOnly(Map<String, String?> data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'For Official Use Only',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 6),

        pw.Row(
          children: [
            _smallField('Admission No.', data['admissionCode']),
            _smallField('Roll No.', data['roll']),
            _smallField('Class / Section',
                '${data['class'] ?? ''} ${data['section'] ?? ''}'),
          ],
        ),

        pw.SizedBox(height: 6),

        pw.Row(
          children: [
            _smallField(
              'Date of Admission',
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
            ),
            _smallField('Remarks', ''),
          ],
        ),

        pw.SizedBox(height: 12),

        _signatureStampRow(),
      ],
    );
  }

  static pw.Widget _smallField(String label, String? value) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(right: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Container(
              height: 18,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.6),
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                value ?? '',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _signatureStampRow() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          children: [
            pw.Container(
              width: 160,
              height: 1,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Authorized Signature',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.Container(
          width: 110,
          height: 55,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.7),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'School Stamp',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }
}

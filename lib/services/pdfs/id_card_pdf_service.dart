import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../supabase_service.dart';

class IdCardGenerator {
  static const int cardsPerPage = 10;

  // Card size (keeps exact 1011x639 ratio)
  static const double templateAspectRatio = 1011 / 593;
  static const double cardWidth = 260;
  static const double cardHeight = cardWidth / templateAspectRatio;

  // Load background from Supabase
  static Future<pw.ImageProvider> loadBackgroundFromSupabase(
      String path) async {
    final bytes = await SupabaseService.client.storage
        .from('id-card-templates')
        .download(path);
    return pw.MemoryImage(bytes);
  }

  // Load student photo safely
  static Future<pw.MemoryImage?> _loadPhotoSafe(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final bytes = await SupabaseService.client.storage
          .from('student-photos')
          .download(path);
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  // Build single card
  static pw.Widget _buildSingleCard(
    Student student,
    String className, //
    pw.ImageProvider bgImage,
    pw.MemoryImage? photo,
  ) {
    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Stack(
        children: [
          // Background
          pw.Positioned.fill(
            child: pw.Image(
              bgImage,
              fit: pw.BoxFit.fill, // IMPORTANT
            ),
          ),

          // Content
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // LEFT SIDE TEXT
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 50), // pushes text below header
                      _info("Name", student.name),
                      _info("Class", className),
                      _info("Roll", student.rollNumber),
                      _info("Father", student.fatherName ?? ""),
                      _info("Address", student.address ?? ""),
                    ],
                  ),
                ),

                pw.SizedBox(width: 10),

                // RIGHT SIDE PHOTO
                _buildPhoto(photo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Label + value row
  static pw.Widget _info(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 9),
          children: [
            pw.TextSpan(
              text: "$label: ",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: value,
            ),
          ],
        ),
      ),
    );
  }


  // Photo box (RIGHT aligned)
  static pw.Widget _buildPhoto(pw.MemoryImage? photo) {
    return pw.Container(
      width: 55,
      height: 65,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        color: PdfColors.grey200,
      ),
      child: photo != null
          ? pw.Image(photo, fit: pw.BoxFit.cover)
          : pw.Center(
              child: pw.Text(
                "No Photo",
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
    );
  }

  // Generate PDF
  static Future<Uint8List> generatePdf({
    required List<Class> classes,
    required List<Student> students,
    required String backgroundAsset,
  }) async {
    final pdf = pw.Document();
    final bgImage = await loadBackgroundFromSupabase(backgroundAsset);
    final Map<String, String> classMap = {
      for (final c in classes) c.id: c.name,
    };


    for (int i = 0; i < students.length; i += cardsPerPage) {
      final chunk = students.sublist(
        i,
        (i + cardsPerPage > students.length)
            ? students.length
            : i + cardsPerPage,
      );

      // preload photos
      final photos = <pw.MemoryImage?>[];
      for (final s in chunk) {
        photos.add(await _loadPhotoSafe(s.photoUrl));
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12, // ↓ was 20
          ),
          build: (_) {
            return pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(chunk.length, (index) {
              final student = chunk[index];
              final className = classMap[student.classId] ?? '';

              return _buildSingleCard(
                student,
                className, // ✅ PASS NAME
                bgImage,
                photos[index],
              );
            }),


            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // Download / Print
  static Future<void> downloadOrPrintPdf({
    required List<Class> classes,
    required List<Student> students,
    required String backgroundAsset,
    String fileName = 'id_cards.pdf',
  }) async {
    final pdfBytes =
        await generatePdf(students: students, backgroundAsset: backgroundAsset, classes: classes);

    if (kIsWeb) {
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } else {
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: fileName,
      );
    }
  }
}

// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:universal_html/html.dart' as html;
//
// import '../models/student_model.dart';
//
// class IDCardPdfService {
//   static final _storage = Supabase.instance.client.storage;
//
//   // --------------------------------------------------------------------------
//   // PUBLIC API
//   // --------------------------------------------------------------------------
//   static Future<void> generatePdf({
//     required List<Student> students,
//   }) async {
//     final pdfBytes = await _buildPdf(students);
//
//     if (kIsWeb) {
//       _downloadWeb(pdfBytes);
//     } else {
//       await Printing.layoutPdf(onLayout: (_) => pdfBytes);
//     }
//   }
//
//   // --------------------------------------------------------------------------
//   // PDF BUILDER
//   // --------------------------------------------------------------------------
//   static Future<Uint8List> _buildPdf(List<Student> students) async {
//     final pdf = pw.Document();
//
//     // Load background template once
//     final bgBytes = await rootBundle.load('assets/idcard_bg.png');
//     final bgImage = pw.MemoryImage(bgBytes.buffer.asUint8List());
//
//     // PRELOAD ALL IMAGES FIRST (fixes your FutureBuilder issue)
//     final Map<String, pw.ImageProvider?> photoMap = {};
//
//     for (final s in students) {
//       photoMap[s.id] = await _loadPhotoSafe(s.photoUrl);
//     }
//
//     // 10 cards per A4 page (2 × 5)
//     const cardsPerPage = 10;
//
//     for (int i = 0; i < students.length; i += cardsPerPage) {
//       final chunk = students.sublist(
//         i,
//         (i + cardsPerPage > students.length)
//             ? students.length
//             : i + cardsPerPage,
//       );
//
//       pdf.addPage(
//         pw.Page(
//           pageFormat: PdfPageFormat.a4,
//           margin: const pw.EdgeInsets.all(20),
//           build: (context) {
//             return pw.GridView(
//               crossAxisCount: 2,
//               childAspectRatio: 85 / 55,
//               children: chunk
//                   .map((s) =>
//                   _buildSingleCard(s, bgImage, photoMap[s.id]))
//                   .toList(),
//             );
//           },
//         ),
//       );
//     }
//
//     return pdf.save();
//   }
//
//   // --------------------------------------------------------------------------
//   // SINGLE CARD BUILDER
//   // --------------------------------------------------------------------------
//   static pw.Widget _buildSingleCard(
//       Student s,
//       pw.ImageProvider bgImage,
//       pw.ImageProvider? photo,
//       ) {
//     return pw.Container(
//       margin: const pw.EdgeInsets.all(5),
//       child: pw.Stack(
//         children: [
//           pw.Positioned.fill(
//             child: pw.Image(bgImage, fit: pw.BoxFit.cover),
//           ),
//
//           pw.Padding(
//             padding: const pw.EdgeInsets.all(12),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 _buildPhoto(photo),
//                 pw.SizedBox(height: 6),
//                 pw.Text(
//                   s.name,
//                   style: pw.TextStyle(
//                     fontSize: 12,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.Text("Class: ${s.classId}",
//                     style: const pw.TextStyle(fontSize: 10)),
//                 pw.Text("Roll: ${s.rollNumber}",
//                     style: const pw.TextStyle(fontSize: 10)),
//                 pw.Text("Father: ${s.fatherName ?? '-'}",
//                     style: const pw.TextStyle(fontSize: 9)),
//                 pw.Text("Address: ${s.address ?? '-'}",
//                     style: const pw.TextStyle(fontSize: 9)),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   // --------------------------------------------------------------------------
//   // PHOTO WIDGET (sync)
//   // --------------------------------------------------------------------------
//   static pw.Widget _buildPhoto(pw.ImageProvider? photo) {
//     return pw.Container(
//       width: 50,
//       height: 60,
//       color: PdfColors.grey300,
//       child: (photo != null)
//           ? pw.Image(photo, fit: pw.BoxFit.cover)
//           : pw.Center(
//         child: pw.Text(
//           "No Photo",
//           style: const pw.TextStyle(fontSize: 8),
//         ),
//       ),
//     );
//   }
//
//   // --------------------------------------------------------------------------
//   // SAFE PHOTO LOADER
//   // --------------------------------------------------------------------------
//   static Future<pw.ImageProvider?> _loadPhotoSafe(String? path) async {
//     if (path == null || path.trim().isEmpty) return null;
//
//     try {
//       final bytes =
//       await _storage.from('student-photos').download(path);
//       return pw.MemoryImage(bytes);
//     } catch (_) {
//       return null;
//     }
//   }
//
//   // --------------------------------------------------------------------------
//   // WEB DOWNLOAD HANDLER
//   // --------------------------------------------------------------------------
//   static void _downloadWeb(Uint8List pdfBytes) {
//     final blob = html.Blob([pdfBytes], 'application/pdf');
//     final url = html.Url.createObjectUrlFromBlob(blob);
//
//     final anchor = html.AnchorElement(href: url)
//       ..download = "id_cards.pdf"
//       ..click();
//
//     html.Url.revokeObjectUrl(url);
//   }
// }

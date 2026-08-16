import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/teacher.dart';

class StaffIdCardPdfService {
  static Future<void> generate(Teacher teacher) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(280, 176),
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColor.fromInt(0xFF134E4A), PdfColor.fromInt(0xFF0D9488)],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(3),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'HAPPY SCHOOL',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0F766E),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF0F766E),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'STAFF ID',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text(
                    teacher.fullName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Staff ID: ${teacher.staffId}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Department: ${teacher.department}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Qualification: ${teacher.qualification}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Phone: ${teacher.phone}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Spacer(),
                  pw.Divider(color: PdfColors.grey300),
                  pw.Text(
                    'Authorized staff identification card',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}

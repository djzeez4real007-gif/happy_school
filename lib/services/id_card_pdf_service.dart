import '../core/theme/app_colors.dart';
import '../core/school_branding.dart';
import '../core/school_profile_controller.dart';
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/student.dart';
import '../models/student_class.dart';

class IdCardPdfService {
  static Future<void> generateStudentIdCard({
    required Student student,
    StudentClass? studentClass,
    String session = '2026/2027',
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? photo;
    if (student.passport.isNotEmpty) {
      try {
        photo = pw.MemoryImage(await File(student.passport).readAsBytes());
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(280, 176),
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColor.fromInt(0xFF0F172A), PdfColor.fromInt(SchoolProfileController.instance.profile.primaryColorValue)],
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
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            SchoolProfileController.instance.name.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(SchoolProfileController.instance.profile.primaryColorValue),
                            ),
                          ),
                          pw.Text(
                            SchoolProfileController.instance.motto.isNotEmpty
                                ? SchoolProfileController.instance.motto
                                : 'Excellence · Integrity · Knowledge',
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(SchoolProfileController.instance.profile.primaryColorValue),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'STUDENT ID',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 72,
                        height: 90,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(8),
                          border: pw.Border.all(
                            color: PdfColor.fromInt(SchoolProfileController.instance.profile.primaryColorValue),
                            width: 1.5,
                          ),
                        ),
                        child: photo != null
                            ? pw.ClipRRect(
                                horizontalRadius: 7,
                                verticalRadius: 7,
                                child: pw.Image(photo, fit: pw.BoxFit.cover),
                              )
                            : pw.Center(
                                child: pw.Text(
                                  student.firstName.isNotEmpty
                                      ? student.firstName[0].toUpperCase()
                                      : 'S',
                                  style: pw.TextStyle(
                                    fontSize: 28,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromInt(SchoolProfileController.instance.profile.primaryColorValue),
                                  ),
                                ),
                              ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              student.fullName,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            _row('Admission', student.admissionNo),
                            _row(
                              'Class',
                              studentClass?.className ?? '—',
                            ),
                            _row('Session', session),
                            _row('Gender', student.gender),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Divider(color: PdfColors.grey300),
                  pw.Text(
                    'This card remains property of ' + SchoolProfileController.instance.name,
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

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

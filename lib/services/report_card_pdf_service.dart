import '../core/school_branding.dart';
import '../core/school_profile_controller.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report_card.dart';

/// Formal, premium school performance report PDF.
class ReportCardPdfService {
  static const _navy = PdfColor.fromInt(0xFF0F172A);
  static const _blue = PdfColor.fromInt(0xFF1E40AF);
  static const _blueSoft = PdfColor.fromInt(0xFFEFF6FF);
  static const _slate = PdfColor.fromInt(0xFF64748B);
  static const _dark = PdfColor.fromInt(0xFF0F172A);
  static const _line = PdfColor.fromInt(0xFFCBD5E1);
  static const _soft = PdfColor.fromInt(0xFFF8FAFC);

  static Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final custom = SchoolBranding.logoBytes;
      if (custom != null && custom.isNotEmpty) {
        return pw.MemoryImage(custom);
      }
      final data = await rootBundle.load('assets/images/school_logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<pw.ImageProvider?> _loadPassport(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _safeFilePart(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static String buildFileName(ReportCard rc) {
    final name = _safeFilePart(rc.studentName);
    final cls = _safeFilePart(rc.className);
    final sess = _safeFilePart(rc.session);
    return '${name}_${cls}_$sess.pdf';
  }

  static Future<void> appendReportCardPages(
    pw.Document pdf,
    ReportCard rc,
  ) async {
    final logo = await _loadLogo();
    final passport = await _loadPassport(rc.passportPath);

    final subjects = rc.subjects;
    final attPct = rc.attendanceTotal <= 0
        ? 0.0
        : (rc.attendancePresent / rc.attendanceTotal) * 100;

    final gradeKeys = ['A1', 'B2', 'B3', 'C4', 'C5', 'C6', 'D7', 'E8', 'F9'];
    final gradeCounts = {for (final g in gradeKeys) g: 0};
    for (final s in subjects) {
      final g = s.grade.toUpperCase();
      if (gradeCounts.containsKey(g)) {
        gradeCounts[g] = gradeCounts[g]! + 1;
      }
    }

    pw.Widget kv(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3.5),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label:  ',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _slate,
                ),
              ),
              pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _dark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget band(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const pw.BoxDecoration(
          color: _blue,
          borderRadius: pw.BorderRadius.only(
            topLeft: pw.Radius.circular(4),
            topRight: pw.Radius.circular(4),
          ),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
        build: (context) => [
          // ========== HEADER ==========
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _blue, width: 1.2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 52,
                    height: 52,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: _line),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                  )
                else
                  pw.Container(
                    width: 52,
                    height: 52,
                    decoration: pw.BoxDecoration(
                      color: _blue,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'HS',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        SchoolProfileController.instance.name.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy,
                          letterSpacing: 1.1,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Excellence · Character · Leadership',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8, color: _slate),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: _blueSoft,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          "${rc.term.toUpperCase()}  ·  STUDENT'S PERFORMANCE REPORT",
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: _blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                // Passport photo
                pw.Container(
                  width: 56,
                  height: 64,
                  decoration: pw.BoxDecoration(
                    color: _soft,
                    border: pw.Border.all(color: _line),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: passport != null
                      ? pw.ClipRRect(
                          horizontalRadius: 4,
                          verticalRadius: 4,
                          child: pw.Image(passport, fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Text(
                            'PHOTO',
                            style:
                                const pw.TextStyle(fontSize: 7, color: _slate),
                          ),
                        ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // ========== STUDENT INFO ==========
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _soft,
              border: pw.Border.all(color: _line),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      kv('Name', rc.studentName),
                      kv('Class', rc.className),
                      kv('Session', rc.session),
                      kv('Term', rc.term),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      kv('Admission No', rc.admissionNo),
                      kv('Position', '${rc.position}'),
                      kv('Overall Grade', rc.overallGrade.isEmpty ? rc.overallRemark : rc.overallGrade),
                      kv('Promotion status', rc.promotionLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // ========== SUBJECT PERFORMANCE ==========
          band('SUBJECT PERFORMANCE'),
          pw.Table(
            border: pw.TableBorder.all(color: _line, width: 0.55),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.6),
              1: const pw.FlexColumnWidth(0.85),
              2: const pw.FlexColumnWidth(0.85),
              3: const pw.FlexColumnWidth(0.85),
              4: const pw.FlexColumnWidth(0.9),
              5: const pw.FlexColumnWidth(0.9),
              6: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
                children: [
                  _th('Subject'),
                  _th('CA1'),
                  _th('CA2'),
                  _th('Exam'),
                  _th('Total'),
                  _th('Grade'),
                  _th('Remark'),
                ],
              ),
              ...List.generate(subjects.length, (i) {
                final s = subjects[i];
                final alt = i.isOdd;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: alt ? _soft : PdfColors.white,
                  ),
                  children: [
                    _td(s.subjectName, align: pw.TextAlign.left),
                    _td(s.ca1.toStringAsFixed(0)),
                    _td(s.ca2.toStringAsFixed(0)),
                    _td(s.exam.toStringAsFixed(0)),
                    _td(s.total.toStringAsFixed(1), bold: true),
                    _td(s.grade, bold: true),
                    _td(s.remark, align: pw.TextAlign.left),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 12),

          // ========== SUMMARY ROW ==========
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  children: [
                    band('PERFORMANCE SUMMARY'),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: _blueSoft,
                        border: pw.Border.all(color: _line),
                      ),
                      child: pw.Column(
                        children: [
                          _sum('Total Score', rc.total.toStringAsFixed(1)),
                          _sum('Average Score', rc.average.toStringAsFixed(2)),
                          _sum('Overall Grade', rc.overallGrade.isEmpty ? rc.overallRemark : rc.overallGrade),
                          _sum('Class Position', '${rc.position}'),
                          _sum('Subjects Offered', '${subjects.length}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  children: [
                    band('ATTENDANCE SUMMARY'),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _line),
                      ),
                      child: pw.Column(
                        children: [
                          _sum('Times Present', '${rc.attendancePresent}'),
                          _sum(
                              'Times School Opened', '${rc.attendanceTotal}'),
                          _sum('Attendance %', attPct.toStringAsFixed(1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // ========== GRADE ANALYSIS (no scale text) ==========
          band('GRADE ANALYSIS'),
          pw.Table(
            border: pw.TableBorder.all(color: _line, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _soft),
                children: [
                  _th('Grade', dark: true),
                  ...gradeKeys.map((g) => _th(g, dark: true)),
                ],
              ),
              pw.TableRow(
                children: [
                  _td('No of Subjects', bold: true),
                  ...gradeKeys.map((g) => _td('${gradeCounts[g]}')),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // ========== REMARKS ==========
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    band("CLASS TEACHER'S REMARK"),
                    pw.Container(
                      width: double.infinity,
                      constraints: const pw.BoxConstraints(minHeight: 50),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _line),
                      ),
                      child: pw.Text(
                        rc.classTeacherRemark,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    band("PRINCIPAL'S REMARK"),
                    pw.Container(
                      width: double.infinity,
                      constraints: const pw.BoxConstraints(minHeight: 50),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _line),
                      ),
                      child: pw.Text(
                        rc.principalRemark,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ========== SIGNATURES ==========
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    width: 150,
                    child: pw.Divider(color: _dark, thickness: 1),
                  ),
                  pw.Text('Class Teacher',
                      style: const pw.TextStyle(fontSize: 8, color: _slate)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    width: 150,
                    child: pw.Divider(color: _dark, thickness: 1),
                  ),
                  pw.Text('Principal',
                      style: const pw.TextStyle(fontSize: 8, color: _slate)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'Generated by ' + SchoolProfileController.instance.name + ' Management System',
              style: const pw.TextStyle(fontSize: 7.5, color: _slate),
            ),
          ),
        ],
      ),
    );

  }

  static Future<Uint8List> buildPdfBytes(ReportCard rc) async {
    final pdf = pw.Document();
    await appendReportCardPages(pdf, rc);
    return pdf.save();
  }

  /// All students in one multipage PDF (one report after another).
  static Future<Uint8List> buildAllPdfBytes(List<ReportCard> cards) async {
    if (cards.isEmpty) {
      throw Exception('No report cards to export');
    }
    final pdf = pw.Document();
    for (final rc in cards) {
      await appendReportCardPages(pdf, rc);
    }
    return pdf.save();
  }

  static String buildBulkFileName(List<ReportCard> cards) {
    if (cards.isEmpty) return 'report_cards.pdf';
    final c = cards.first;
    final cls = _safeFilePart(c.className);
    final sess = _safeFilePart(c.session);
    final term = _safeFilePart(c.term);
    return 'ReportCards_${cls}_${sess}_$term.pdf';
  }

  static pw.Widget _th(String text, {bool dark = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: dark ? _dark : PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _td(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _dark,
        ),
      ),
    );
  }

  static pw.Widget _sum(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _slate)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _dark,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printReportCard(ReportCard reportCard) async {
    final bytes = await buildPdfBytes(reportCard);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: buildFileName(reportCard).replaceAll('.pdf', ''),
    );
  }

  static Future<void> shareReportCard(ReportCard reportCard) async {
    final bytes = await buildPdfBytes(reportCard);
    await Printing.sharePdf(
      bytes: bytes,
      filename: buildFileName(reportCard),
    );
  }

  static Future<void> generatePdf(ReportCard reportCard) async {
    await printReportCard(reportCard);
  }

  static Future<void> printAllReportCards(List<ReportCard> cards) async {
    final bytes = await buildAllPdfBytes(cards);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: buildBulkFileName(cards).replaceAll('.pdf', ''),
    );
  }

  static Future<void> shareAllReportCards(List<ReportCard> cards) async {
    final bytes = await buildAllPdfBytes(cards);
    await Printing.sharePdf(
      bytes: bytes,
      filename: buildBulkFileName(cards),
    );
  }
}

import '../core/school_branding.dart';
import '../core/school_profile_controller.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/result.dart';

/// Formal beige academic transcript PDF.
class TranscriptPdfService {
  static const _beige = PdfColor.fromInt(0xFFF7F1E3);
  static const _beigeDark = PdfColor.fromInt(0xFFE8DFC8);
  static const _ink = PdfColor.fromInt(0xFF3D3226);
  static const _muted = PdfColor.fromInt(0xFF7A6A55);
  static const _line = PdfColor.fromInt(0xFFC9BBA0);
  static const _headerBg = PdfColor.fromInt(0xFF5C4A32);

  static int _termOrder(String t) {
    final x = t.toLowerCase();
    if (x.contains('first')) return 1;
    if (x.contains('second')) return 2;
    if (x.contains('third')) return 3;
    return 9;
  }

  static Future<Uint8List?> _logo() async {
    final custom = SchoolBranding.logoBytes;
    if (custom != null && custom.isNotEmpty) return custom;
    for (final path in [
      'assets/images/school_logo.png',
      'assets/images/logo.png',
    ]) {
      try {
        final data = await rootBundle.load(path);
        return data.buffer.asUint8List();
      } catch (_) {}
    }
    return null;
  }

  static Future<Uint8List> buildPdf({
    required Map<String, dynamic> student,
    required List<Result> results,
  }) async {
    final pdf = pw.Document();
    final logo = await _logo();
    final issued = DateFormat('dd MMMM yyyy').format(DateTime.now());

    final grouped = <String, Map<String, List<Result>>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.session, () => {});
      grouped[r.session]!.putIfAbsent(r.term, () => []);
      grouped[r.session]![r.term]!.add(r);
    }
    final sessions = grouped.keys.toList()..sort();

    double sumAll = 0;
    int countAll = 0;
    int passCount = 0;
    for (final r in results) {
      sumAll += r.total;
      countAll++;
      if (r.isPassed) passCount++;
    }
    final overallAvg = countAll == 0 ? 0.0 : sumAll / countAll;

    // Use ONLY pageTheme (do not also set pageFormat/margin on MultiPage)
    final theme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(color: _beige),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: theme,
        header: (ctx) => pw.Column(
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: _line, width: 1),
                      image: pw.DecorationImage(
                        image: pw.MemoryImage(logo),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  )
                else
                  pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: _headerBg, width: 1.5),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'HS',
                        style: pw.TextStyle(
                          color: _headerBg,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 13,
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
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 17,
                          color: _headerBg,
                          letterSpacing: 1.4,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Secondary School · Academic Records Office',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 9, color: _muted),
                      ),
                      pw.Text(
                        SchoolProfileController.instance.address,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 8, color: _muted),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 50),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 7),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: _headerBg, width: 1.4),
                  bottom: pw.BorderSide(color: _headerBg, width: 1.4),
                ),
              ),
              child: pw.Text(
                'OFFICIAL ACADEMIC TRANSCRIPT',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: _headerBg,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (ctx) {
          final studentName = '${student['fullName'] ?? ''}'.trim();
          final adm = '${student['admissionNo'] ?? ''}'.trim();
          final parts = <String>[];
          if (studentName.isNotEmpty) parts.add(studentName);
          if (adm.isNotEmpty) parts.add(adm);
          parts.add(SchoolProfileController.instance.name + ' ERP');
          final label = parts.join(' · ');
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 6),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    label,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ],
            ),
          );
        },
        build: (ctx) {
          final widgets = <pw.Widget>[
            pw.Text(
              'Student Information',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: _headerBg,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _beigeDark,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: _line, width: 0.6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _info('Student Name', '${student['fullName'] ?? ''}'),
                        _info(
                            'Admission No.', '${student['admissionNo'] ?? ''}'),
                        if ('${student['gender'] ?? ''}'.trim().isNotEmpty)
                          _info('Gender', '${student['gender']}'),
                        if ('${student['dateOfBirth'] ?? ''}'.trim().isNotEmpty)
                          _info('Date of Birth', '${student['dateOfBirth']}'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _info('Issuing Institution', SchoolProfileController.instance.name),
                        _info('Document Type', 'Academic Transcript'),
                        _info('Date Issued', issued),
                        _info(
                          'Record Status',
                          results.isEmpty ? 'No results' : 'Active',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Academic Record',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: _headerBg,
              ),
            ),
            pw.SizedBox(height: 8),
          ];

          if (results.isEmpty) {
            widgets.add(
              pw.Text(
                'No academic results recorded for this student.',
                style: pw.TextStyle(fontSize: 9, color: _muted),
              ),
            );
          } else {
            for (final session in sessions) {
              final termsMap = grouped[session]!;
              final terms = termsMap.keys.toList()
                ..sort((a, b) => _termOrder(a).compareTo(_termOrder(b)));

              for (final term in terms) {
                final list = List<Result>.from(termsMap[term]!)
                  ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
                final avg = list.isEmpty
                    ? 0.0
                    : list.map((r) => r.total).fold(0.0, (a, b) => a + b) /
                        list.length;

                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      '$session  ·  $term',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: _ink,
                      ),
                    ),
                  ),
                );

                widgets.add(
                  pw.Table.fromTextArray(
                    headers: const [
                      'Subject',
                      'Code',
                      'CA1',
                      'CA2',
                      'Exam',
                      'Total',
                      'Grade',
                      'Remark',
                    ],
                    data: list
                        .map((r) => [
                              r.subjectName,
                              r.subjectCode,
                              r.ca1.toStringAsFixed(0),
                              r.ca2.toStringAsFixed(0),
                              r.exam.toStringAsFixed(0),
                              r.total.toStringAsFixed(0),
                              r.grade,
                              r.remark,
                            ])
                        .toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                      color: PdfColors.white,
                    ),
                    headerDecoration:
                        const pw.BoxDecoration(color: _headerBg),
                    cellStyle: pw.TextStyle(fontSize: 8, color: _ink),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerAlignment: pw.Alignment.centerLeft,
                    border: pw.TableBorder.all(color: _line, width: 0.4),
                    oddRowDecoration:
                        const pw.BoxDecoration(color: _beigeDark),
                  ),
                );

                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3, bottom: 10),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Term average: ${avg.toStringAsFixed(1)}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _muted,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
          }

          widgets.add(pw.SizedBox(height: 4));
          widgets.add(
            pw.Text(
              'Academic Summary',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: _headerBg,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _beigeDark,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: _line, width: 0.6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _summary('Subjects recorded', '$countAll'),
                  _summary('Overall average', overallAvg.toStringAsFixed(1)),
                  _summary('Subjects passed', '$passCount'),
                  _summary(
                    'Pass rate',
                    countAll == 0
                        ? '—'
                        : '${((passCount / countAll) * 100).toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 28));
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _sign('Principal'),
                _sign('Academic Officer'),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 20));
          widgets.add(
            pw.Text(
              'This transcript is a certified summary of the student’s academic performance. '
              'Any alteration invalidates this document.',
              style: pw.TextStyle(
                fontSize: 8,
                color: _ink,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _info(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 8,
                color: _muted,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: value.isEmpty ? '—' : value,
              style: pw.TextStyle(fontSize: 8, color: _ink),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _summary(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7, color: _muted)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    );
  }

  static pw.Widget _sign(String title) {
    return pw.Column(
      children: [
        pw.Container(
          width: 140,
          height: 28,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _ink, width: 0.6),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.Text(
          'Signature & Date',
          style: pw.TextStyle(fontSize: 7, color: _muted),
        ),
      ],
    );
  }

  static Future<void> printTranscript({
    required Map<String, dynamic> student,
    required List<Result> results,
  }) async {
    final bytes = await buildPdf(student: student, results: results);
    final name = '${student['fullName'] ?? 'Student'}_${student['admissionNo'] ?? ''}_Transcript'
        .replaceAll(RegExp(r'[^\w\-]+'), '_');
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: name,
    );
  }

  static Future<void> shareTranscript({
    required Map<String, dynamic> student,
    required List<Result> results,
  }) async {
    final bytes = await buildPdf(student: student, results: results);
    final directory = await getApplicationDocumentsDirectory();
    final full = '${student['fullName'] ?? 'Student'}_${student['admissionNo'] ?? ''}'
        .trim()
        .replaceAll(RegExp(r'[^\w\-]+'), '_');
    final file = File('${directory.path}/Transcript_$full.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text:
            'Academic Transcript — ${student['fullName'] ?? ''} (${student['admissionNo'] ?? ''})',
      ),
    );
  }
}

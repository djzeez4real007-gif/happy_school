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

class TranscriptPdfService {
  static const _navy = PdfColor.fromInt(0xFF0F172A);
  static const _blue = PdfColor.fromInt(0xFF1D4ED8);
  static const _slate = PdfColor.fromInt(0xFF64748B);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);

  static int _termOrder(String t) {
    final x = t.toLowerCase();
    if (x.contains('first')) return 1;
    if (x.contains('second')) return 2;
    if (x.contains('third')) return 3;
    return 9;
  }

  static Future<Uint8List?> _logo() async {
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
    final generated =
        DateFormat('dd MMM yyyy · hh:mm a').format(DateTime.now());

    final grouped = <String, Map<String, List<Result>>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.session, () => {});
      grouped[r.session]!.putIfAbsent(r.term, () => []);
      grouped[r.session]![r.term]!.add(r);
    }
    final sessions = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => pw.Column(
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 48,
                    height: 48,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      image: pw.DecorationImage(
                        image: pw.MemoryImage(logo),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  )
                else
                  pw.Container(
                    width: 48,
                    height: 48,
                    decoration: const pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: _blue,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'HS',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
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
                        'HAPPY SCHOOL',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                          color: _navy,
                        ),
                      ),
                      pw.Text(
                        'Official Academic Transcript',
                        style: pw.TextStyle(color: _slate, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: _line),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: _line),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated $generated',
                  style: pw.TextStyle(color: _slate, fontSize: 8),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: pw.TextStyle(color: _slate, fontSize: 8),
                ),
              ],
            ),
          ],
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F5F9),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${student['fullName'] ?? ''}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: _navy,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Admission No: ${student['admissionNo'] ?? ''}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if ('${student['gender'] ?? ''}'.trim().isNotEmpty)
                    pw.Text(
                      'Gender: ${student['gender']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if ('${student['dateOfBirth'] ?? ''}'.trim().isNotEmpty)
                    pw.Text(
                      'Date of birth: ${student['dateOfBirth']}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
          ];

          if (results.isEmpty) {
            widgets.add(pw.Text('No results recorded.'));
          } else {
            for (final session in sessions) {
              final termsMap = grouped[session]!;
              final terms = termsMap.keys.toList()
                ..sort((a, b) => _termOrder(a).compareTo(_termOrder(b)));

              widgets.add(
                pw.Text(
                  'Session $session',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: _blue,
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 6));

              for (final term in terms) {
                final list = termsMap[term]!;
                final avg = list.isEmpty
                    ? 0.0
                    : list.map((r) => r.total).fold(0.0, (a, b) => a + b) /
                        list.length;

                widgets.add(
                  pw.Text(
                    '$term  ·  Average ${avg.toStringAsFixed(1)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 4));
                widgets.add(
                  pw.Table.fromTextArray(
                    headers: [
                      'Subject',
                      'CA1',
                      'CA2',
                      'Exam',
                      'Total',
                      'Grade',
                      'Remark'
                    ],
                    data: list
                        .map((r) => [
                              r.subjectName,
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
                    headerDecoration: const pw.BoxDecoration(color: _blue),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignment: pw.Alignment.centerLeft,
                    border: pw.TableBorder.all(color: _line, width: 0.5),
                  ),
                );
                widgets.add(pw.SizedBox(height: 12));
              }
            }
          }

          widgets.add(pw.SizedBox(height: 16));
          widgets.add(
            pw.Text(
              'This is a computer-generated academic transcript from Happy School ERP.',
              style: pw.TextStyle(color: _slate, fontSize: 8),
            ),
          );

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printTranscript({
    required Map<String, dynamic> student,
    required List<Result> results,
  }) async {
    final bytes = await buildPdf(student: student, results: results);
    final name = '${student['fullName'] ?? 'Student'}_Transcript'
        .replaceAll(RegExp(r'[^\w\-]+'), '_');
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: name,
    );
  }

  static Future<void> shareTranscript({
    required Map<String, dynamic> student,
    required List<Result> results,
  }) async {
    final bytes = await buildPdf(student: student, results: results);
    final directory = await getApplicationDocumentsDirectory();
    final safe = '${student['admissionNo'] ?? 'student'}'
        .replaceAll(RegExp(r'[^\w\-]+'), '_');
    final file = File('${directory.path}/transcript_$safe.pdf');
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

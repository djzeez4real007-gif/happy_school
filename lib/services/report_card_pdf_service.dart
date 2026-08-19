import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_card.dart';

class ReportCardPdfService {
  static Future<File> generatePdf(ReportCard reportCard) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),

        build: (context) => [
          // ==============================
          // SCHOOL HEADER
          // ==============================
          pw.Center(
            child: pw.Text(
              'HAPPY SCHOOL',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Center(
            child: pw.Text(
              'STUDENT REPORT CARD',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 20),

          // ==============================
          // STUDENT INFORMATION
          // ==============================
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Student: ${reportCard.studentName}'),
                pw.Text('Admission No: ${reportCard.admissionNo}'),
                pw.Text('Class: ${reportCard.className}'),
                pw.Text('Session: ${reportCard.session}'),
                pw.Text('Term: ${reportCard.term}'),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ==============================
          // SUBJECT RESULTS TABLE
          // ==============================
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: const [
              'Subject',
              'CA1',
              'CA2',
              'Exam',
              'Total',
              'Grade',
              'Remark',
            ],
            data: reportCard.subjects.map((subject) {
              return [
                subject.subjectName,
                subject.ca1.toStringAsFixed(0),
                subject.ca2.toStringAsFixed(0),
                subject.exam.toStringAsFixed(0),
                subject.total.toStringAsFixed(0),
                subject.grade,
                subject.remark,
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          // ==============================
          // PERFORMANCE SUMMARY
          // ==============================
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Total Score: '
                  '${reportCard.total.toStringAsFixed(2)}',
                ),
                pw.Text(
                  'Average: '
                  '${reportCard.average.toStringAsFixed(2)}',
                ),
                pw.Text(
                  'Overall Grade: '
                  '${reportCard.overallGrade}',
                ),
                pw.Text(
                  'Overall Remark: '
                  '${reportCard.overallRemark}',
                ),
                pw.Text(
                  'Position in Class: '
                  '${reportCard.position}',
                ),
                pw.Text(
                  'Attendance: '
                  '${reportCard.attendancePresent}/'
                  '${reportCard.attendanceTotal}',
                ),
                pw.Text(
                  'Promotion: '
                  '${reportCard.promotionLabel}',
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ==============================
          // CLASS TEACHER REMARK
          // ==============================
          pw.Text(
            "Class Teacher's Remark",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 5),

          pw.Text(reportCard.classTeacherRemark),

          pw.SizedBox(height: 15),

          // ==============================
          // PRINCIPAL REMARK
          // ==============================
          pw.Text(
            "Principal's Remark",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 5),

          pw.Text(reportCard.principalRemark),

          pw.SizedBox(height: 40),

          // ==============================
          // SIGNATURES
          // ==============================
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 160, child: pw.Divider()),
                  pw.Text('Class Teacher'),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 160, child: pw.Divider()),
                  pw.Text('Principal'),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          pw.Center(
            child: pw.Text(
              'Generated by Happy School Management System',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );

    // ==============================
    // SAVE FILE
    // ==============================

    final directory = await getApplicationDocumentsDirectory();

    final safeTerm = reportCard.term.replaceAll(' ', '_').replaceAll('/', '_');

    final file = File(
      '${directory.path}/'
      '${reportCard.admissionNo}_'
      '${safeTerm}_ReportCard.pdf',
    );

    await file.writeAsBytes(await pdf.save());

    return file;
  }


  static Future<void> printReportCard(ReportCard reportCard) async {
    final file = await generatePdf(reportCard);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: '${reportCard.studentName}_report_card',
    );
  }

  static Future<void> shareReportCard(ReportCard reportCard) async {
    final file = await generatePdf(reportCard);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text:
            'Report card — ${reportCard.studentName} (${reportCard.session} · ${reportCard.term})',
      ),
    );
  }
}

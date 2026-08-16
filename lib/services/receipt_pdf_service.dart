import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/student_fee_payment.dart';

class ReceiptPdfService {
  // =====================================================
  // GENERATE RECEIPT PDF
  // =====================================================

  static Future<File> generateReceipt(StudentFeePayment payment) async {
    final pdf = pw.Document();

    // ==============================
    // LOAD FONTS
    // ==============================

    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );

    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );

    final generatedDate = DateFormat(
      'dd MMM yyyy  hh:mm a',
    ).format(DateTime.now());

    // ==============================
    // CREATE PDF PAGE
    // ==============================

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) {
          return [
            // ==============================
            // HEADER
            // ==============================
            pw.Center(
              child: pw.Text(
                'HAPPY SCHOOL',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 5),

            pw.Center(
              child: pw.Text(
                'OFFICIAL SCHOOL FEE RECEIPT',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.Divider(),

            pw.SizedBox(height: 20),

            // ==============================
            // STUDENT INFORMATION
            // ==============================
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600),
              ),
              child: pw.Column(
                children: [
                  _infoRow('Receipt Number', payment.receiptNo),
                  _infoRow('Student Name', payment.studentName),
                  _infoRow('Admission No', payment.admissionNo),
                  _infoRow('Class', payment.className),
                  _infoRow('Payment Method', payment.paymentMethod),
                  _infoRow('Session', payment.session),
                  _infoRow('Term', payment.term),
                  _infoRow('Payment Date', payment.paymentDate),
                  _infoRow('Generated', generatedDate),
                ],
              ),
            ),

            pw.SizedBox(height: 25),

            // ==============================
            // FEE DETAILS
            // ==============================
            pw.Text(
              'FEE DETAILS',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 10),

            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey500),
              ),
              child: pw.Column(
                children: [
                  _infoRow('Tuition Fee', money(payment.tuitionFee)),
                  _infoRow('Examination Fee', money(payment.examinationFee)),
                  _infoRow('PTA Fee', money(payment.ptaFee)),
                  _infoRow('ICT Fee', money(payment.ictFee)),
                  _infoRow('Sport Fee', money(payment.sportFee)),
                  _infoRow('Development Levy', money(payment.developmentLevy)),
                  _infoRow('Other Charges', money(payment.otherCharges)),

                  pw.Divider(),

                  _infoRow('Total School Fee', money(payment.totalSchoolFee)),
                ],
              ),
            ),

            pw.SizedBox(height: 25),

            // ==============================
            // PAYMENT SUMMARY
            // ==============================
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                border: pw.Border.all(color: PdfColors.green700),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'AMOUNT PAID',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  pw.Text(
                    'NGN ${money(payment.amountPaid)}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  pw.Text(
                    'Balance: NGN ${money(payment.balance)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 40),

            // ==============================
            // SIGNATURES
            // ==============================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 180, child: pw.Divider()),
                    pw.Text('Cashier'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 180, child: pw.Divider()),
                    pw.Text('Principal'),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 40),

            pw.Center(
              child: pw.Text(
                'Thank you for your payment.',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),

            pw.SizedBox(height: 5),

            pw.Center(
              child: pw.Text(
                'Generated by Happy School Management System',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ];
        },
      ),
    );

    // ==============================
    // SAVE PDF FILE
    // ==============================

    final directory = await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/${payment.receiptNo}.pdf');

    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // =====================================================
  // PRINT RECEIPT
  // =====================================================

  static Future<void> printReceipt(StudentFeePayment payment) async {
    try {
      final file = await generateReceipt(payment);

      await Printing.layoutPdf(
        onLayout: (format) async {
          return file.readAsBytes();
        },
      );
    } catch (e) {
      throw Exception('Print failed: $e');
    }
  }

  // =====================================================
  // SHARE RECEIPT
  // =====================================================

  static Future<void> shareReceipt(StudentFeePayment payment) async {
    try {
      final file = await generateReceipt(payment);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Happy School Fee Receipt - ${payment.studentName}',
        ),
      );
    } catch (e) {
      throw Exception('Share failed: $e');
    }
  }

  // =====================================================
  // FORMAT MONEY
  // =====================================================

  static String money(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  // =====================================================
  // PDF INFORMATION ROW
  // =====================================================

  static pw.Widget _infoRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(flex: 3, child: pw.Text(value)),
        ],
      ),
    );
  }
}

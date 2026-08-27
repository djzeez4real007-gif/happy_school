import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/student_fee_payment.dart';

class ReceiptPdfService {
  static const _green = PdfColor.fromInt(0xFF059669);
  static const _greenDark = PdfColor.fromInt(0xFF047857);
  static const _greenDeep = PdfColor.fromInt(0xFF065F46);
  static const _mint = PdfColor.fromInt(0xFFECFDF5);
  static const _slate = PdfColor.fromInt(0xFF64748B);
  static const _dark = PdfColor.fromInt(0xFF0F172A);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);
  static const _redSoft = PdfColor.fromInt(0xFFFEE2E2);
  static const _red = PdfColor.fromInt(0xFFDC2626);

  static Future<File> generateReceipt(StudentFeePayment payment) async {
    final pdf = pw.Document();
    final generatedDate =
        DateFormat('dd MMM yyyy · hh:mm a').format(DateTime.now());
    final settled = payment.balance <= 0.01;

    String money(double amount) {
      return 'NGN ${NumberFormat('#,##0.00').format(amount)}';
    }

    String formatDate(String raw) {
      try {
        return DateFormat('dd MMM yyyy · HH:mm').format(DateTime.parse(raw));
      } catch (_) {
        return raw;
      }
    }

    pw.Widget infoRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 130,
              child: pw.Text(
                label,
                style: pw.TextStyle(color: _slate, fontSize: 10),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: _dark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget feeRow(String label, double amount, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: bold ? _dark : _slate,
              ),
            ),
            pw.Text(
              money(amount),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: _dark,
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line, width: 1),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ===== Green header =====
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(24, 22, 24, 22),
                  decoration: const pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [_greenDeep, _greenDark, _green],
                      begin: pw.Alignment.topLeft,
                      end: pw.Alignment.bottomRight,
                    ),
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(15),
                      topRight: pw.Radius.circular(15),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: 42,
                        height: 42,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0x33FFFFFF),
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'HS',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'HAPPY SCHOOL',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Official Fee Payment Receipt',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0x28FFFFFF),
                          borderRadius: pw.BorderRadius.circular(20),
                          border: pw.Border.all(
                            color: PdfColor.fromInt(0x40FFFFFF),
                          ),
                        ),
                        child: pw.Text(
                          payment.receiptNo,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== Amount band =====
                pw.Container(
                  color: _mint,
                  padding: const pw.EdgeInsets.symmetric(vertical: 18),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'AMOUNT PAID',
                        style: pw.TextStyle(
                          color: _greenDark,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        money(payment.amountPaid),
                        style: pw.TextStyle(
                          color: _greenDeep,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: pw.BoxDecoration(
                          color: settled ? _mint : _redSoft,
                          borderRadius: pw.BorderRadius.circular(16),
                          border: pw.Border.all(
                            color: settled ? _green : _red,
                          ),
                        ),
                        child: pw.Text(
                          settled
                              ? 'FULLY PAID'
                              : 'BALANCE ${money(payment.balance)}',
                          style: pw.TextStyle(
                            color: settled ? _greenDeep : _red,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== Body =====
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'STUDENT DETAILS',
                        style: pw.TextStyle(
                          color: _slate,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFF8FAFC),
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: _line),
                        ),
                        child: pw.Column(
                          children: [
                            infoRow('Student', payment.studentName),
                            infoRow('Admission No', payment.admissionNo),
                            infoRow('Class', payment.className),
                            infoRow('Session', payment.session),
                            infoRow('Term', payment.term),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 16),
                      pw.Text(
                        'FEE BREAKDOWN',
                        style: pw.TextStyle(
                          color: _slate,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFF8FAFC),
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: _line),
                        ),
                        child: pw.Column(
                          children: [
                            feeRow('Tuition Fee', payment.tuitionFee),
                            feeRow('Examination Fee', payment.examinationFee),
                            feeRow('ICT Fee', payment.ictFee),
                            feeRow('Sport Fee', payment.sportFee),
                            feeRow('Development Levy', payment.developmentLevy),
                            feeRow('PTA Fee', payment.ptaFee),
                            feeRow('Other Charges', payment.otherCharges),
                            pw.Divider(color: _line, height: 14),
                            feeRow(
                              'Total School Fee',
                              payment.totalSchoolFee,
                              bold: true,
                            ),
                            feeRow('Amount Paid', payment.amountPaid, bold: true),
                            if (payment.discountAmount > 0.01)
                              feeRow('Discount', payment.discountAmount),

                            feeRow('Balance', payment.balance, bold: true),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 16),
                      pw.Text(
                        'PAYMENT INFO',
                        style: pw.TextStyle(
                          color: _slate,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFFF8FAFC),
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: _line),
                        ),
                        child: pw.Column(
                          children: [
                            infoRow('Method', payment.paymentMethod),
                            infoRow('Date', formatDate(payment.paymentDate)),
                            infoRow('Generated', generatedDate),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 22),
                      pw.Center(
                        child: pw.Text(
                          'Thank you for your payment.\nThis is a computer-generated receipt.',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: _slate,
                            fontSize: 9,
                            height: 1.4,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Center(
                        child: pw.Text(
                          'Happy School Management System',
                          style: pw.TextStyle(
                            color: _greenDark,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final safeNo =
        payment.receiptNo.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    final file = File('${directory.path}/receipt_$safeNo.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> printReceipt(StudentFeePayment payment) async {
    final file = await generateReceipt(payment);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Receipt_${payment.receiptNo}',
    );
  }

  static Future<void> shareReceipt(StudentFeePayment payment) async {
    final file = await generateReceipt(payment);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Happy School Fee Receipt — ${payment.studentName}',
      ),
    );
  }

  static String money(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }
}

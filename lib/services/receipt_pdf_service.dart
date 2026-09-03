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

import '../models/student_fee_payment.dart';

class ReceiptPdfService {
  static const _green = PdfColor.fromInt(0xFF059669);
  static const _greenDark = PdfColor.fromInt(0xFF047857);
  static const _greenDeep = PdfColor.fromInt(0xFF065F46);
  static const _mint = PdfColor.fromInt(0xFFECFDF5);
  static const _slate = PdfColor.fromInt(0xFF64748B);
  static const _dark = PdfColor.fromInt(0xFF0F172A);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _redSoft = PdfColor.fromInt(0xFFFEE2E2);

  static String _money(double amount) =>
      'NGN ${NumberFormat('#,##0.00').format(amount)}';

  static String _formatDate(String raw) {
    try {
      return DateFormat('dd MMM yyyy · HH:mm').format(DateTime.parse(raw));
    } catch (_) {
      return raw.isEmpty ? '—' : raw;
    }
  }

  static Future<Uint8List?> _logoBytes() async {
    final custom = SchoolBranding.logoBytes;
    if (custom != null && custom.isNotEmpty) return custom;
    try {
      final data = await rootBundle.load('assets/images/school_logo.png');
      return data.buffer.asUint8List();
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/images/logo.png');
        return data.buffer.asUint8List();
      } catch (_) {
        return null;
      }
    }
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style: pw.TextStyle(color: _slate, fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '—' : value,
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

  static pw.Widget _feeRow(String label, double amount, {bool bold = false}) {
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
              color: _dark,
            ),
          ),
          pw.Text(
            _money(amount),
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

  static Future<Uint8List> buildPdfBytes(StudentFeePayment payment) async {
    final pdf = pw.Document();
    final settled = payment.balance <= 0.01;
    final generated =
        DateFormat('dd MMM yyyy · hh:mm a').format(DateTime.now());
    final logo = await _logoBytes();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 22),
                decoration: pw.BoxDecoration(
                  color: _greenDeep,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(12),
                    topRight: pw.Radius.circular(12),
                  ),
                ),
                child: pw.Column(
                  children: [
                    if (logo != null)
                      pw.Container(
                        width: 48,
                        height: 48,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.white,
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
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.white,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'HS',
                            style: pw.TextStyle(
                              color: _greenDeep,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      SchoolProfileController.instance.name.toUpperCase(),
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
                          color: PdfColors.white, fontSize: 11),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0x28FFFFFF),
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        payment.receiptNo.isEmpty
                            ? '—'
                            : payment.receiptNo,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              pw.Container(
                color: _mint,
                padding: const pw.EdgeInsets.symmetric(vertical: 16),
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
                      _money(payment.amountPaid),
                      style: pw.TextStyle(
                        color: _greenDeep,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: settled ? _mint : _redSoft,
                        borderRadius: pw.BorderRadius.circular(16),
                        border: pw.Border.all(
                            color: settled ? _green : _red),
                      ),
                      child: pw.Text(
                        settled
                            ? 'FULLY PAID'
                            : 'BALANCE ${_money(payment.balance)}',
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

              pw.SizedBox(height: 16),

              // Student
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
                  border: pw.Border.all(color: _line),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _infoRow('Student name', payment.studentName),
                    _infoRow('Admission no.', payment.admissionNo),
                    _infoRow('Class', payment.className),
                    _infoRow('Session', payment.session),
                    _infoRow('Term', payment.term),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Fee breakdown
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
                  border: pw.Border.all(color: _line),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    if (payment.tuitionFee > 0)
                      _feeRow('Tuition', payment.tuitionFee),
                    if (payment.examinationFee > 0)
                      _feeRow('Examination', payment.examinationFee),
                    if (payment.ictFee > 0) _feeRow('ICT', payment.ictFee),
                    if (payment.sportFee > 0)
                      _feeRow('Sport', payment.sportFee),
                    if (payment.developmentLevy > 0)
                      _feeRow('Development levy', payment.developmentLevy),
                    if (payment.ptaFee > 0) _feeRow('PTA', payment.ptaFee),
                    if (payment.otherCharges > 0)
                      _feeRow('Other charges', payment.otherCharges),
                    pw.Divider(color: _line),
                    _feeRow('Total school fee', payment.totalSchoolFee,
                        bold: true),
                    _feeRow('Amount paid', payment.amountPaid, bold: true),
                    if (payment.discountAmount > 0)
                      _feeRow('Discount', payment.discountAmount),
                    _feeRow('Balance', payment.balance, bold: true),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Payment meta
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
                  border: pw.Border.all(color: _line),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _infoRow('Method', payment.paymentMethod),
                    _infoRow('Date', _formatDate(payment.paymentDate)),
                    _infoRow('Generated', generated),
                  ],
                ),
              ),

              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Thank you for your payment.\nThis is a computer-generated receipt.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      color: _slate, fontSize: 9, height: 1.4),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  SchoolProfileController.instance.name + ' Management System',
                  style: pw.TextStyle(
                    color: _greenDark,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<File> generateReceipt(StudentFeePayment payment) async {
    final bytes = await buildPdfBytes(payment);
    final directory = await getApplicationDocumentsDirectory();
    final safeNo =
        payment.receiptNo.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    final file = File('${directory.path}/receipt_$safeNo.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> printReceipt(StudentFeePayment payment) async {
    final bytes = await buildPdfBytes(payment);
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
        text: '${SchoolProfileController.instance.name} Fee Receipt — ${payment.studentName}',
      ),
    );
  }
}

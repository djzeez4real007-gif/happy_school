import 'package:flutter/material.dart';

import '../../models/student_fee_payment.dart';
import '../../services/receipt_pdf_service.dart';

class ReceiptScreen extends StatelessWidget {
  final StudentFeePayment payment;

  const ReceiptScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        actions: [
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print_rounded),
            onPressed: () async {
              await ReceiptPdfService.generateReceipt(payment);
            },
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Close'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        backgroundColor: const Color(0xFF1D4ED8),
        icon: const Icon(Icons.close_rounded),
        label: const Text('Close Receipt'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const Center(
                  child: Text(
                    'HAPPY SCHOOL',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                const Center(child: Text('Student Fee Payment Receipt')),
                const Divider(),
                receiptRow('Receipt No', payment.receiptNo),
                receiptRow('Admission No', payment.admissionNo),
                receiptRow('Student Name', payment.studentName),
                receiptRow('Class', payment.className),
                receiptRow('Session', payment.session),
                receiptRow('Term', payment.term),
                const SizedBox(height: 20),
                const Text(
                  'Fee Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                receiptRow('Tuition Fee', '₦${payment.tuitionFee}'),
                receiptRow('Development Levy', '₦${payment.developmentLevy}'),
                receiptRow('Examination Fee', '₦${payment.examinationFee}'),
                receiptRow('ICT Fee', '₦${payment.ictFee}'),
                receiptRow('Sport Fee', '₦${payment.sportFee}'),
                receiptRow('PTA Fee', '₦${payment.ptaFee}'),
                receiptRow('Other Charges', '₦${payment.otherCharges}'),
                const Divider(),
                receiptRow('Total School Fee', '₦${payment.totalSchoolFee}', bold: true),
                receiptRow('Amount Paid', '₦${payment.amountPaid}', bold: true),
                receiptRow('Balance', '₦${payment.balance}', bold: true),
                const SizedBox(height: 12),
                receiptRow('Payment Method', payment.paymentMethod),
                receiptRow('Payment Date', payment.paymentDate),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget receiptRow(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}

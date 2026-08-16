import 'package:flutter/material.dart';

import '../../models/student_fee_payment.dart';
import '../../services/receipt_pdf_service.dart';

class ReceiptDetailsScreen extends StatelessWidget {
  final StudentFeePayment payment;

  const ReceiptDetailsScreen({super.key, required this.payment});

  Widget infoTile(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receipt Details")),

      body: ListView(
        padding: const EdgeInsets.all(15),

        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.green, size: 70),

                  const SizedBox(height: 10),

                  const Text(
                    "OFFICIAL SCHOOL RECEIPT",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    payment.receiptNo,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          infoTile("Student Name", payment.studentName),

          infoTile("Admission Number", payment.admissionNo),

          infoTile(
            "Amount Paid",
            "NGN ${payment.amountPaid.toStringAsFixed(2)}",
          ),

          infoTile("Payment Method", payment.paymentMethod),

          infoTile("Session", payment.session),

          infoTile("Term", payment.term),

          infoTile("Date", payment.paymentDate),

          const SizedBox(height: 30),

          SizedBox(
            height: 50,

            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),

              label: const Text("REPRINT RECEIPT"),

              onPressed: () async {
                await ReceiptPdfService.generateReceipt(payment);

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Receipt Generated Successfully"),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 50,

            child: OutlinedButton.icon(
              icon: const Icon(Icons.share),

              label: const Text("EXPORT / SHARE PDF"),

              onPressed: () async {
                await ReceiptPdfService.generateReceipt(payment);

                if (!context.mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("PDF Ready")));
              },
            ),
          ),
        ],
      ),
    );
  }
}

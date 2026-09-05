import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';
import '../../core/school_profile_controller.dart';

import '../../models/student_fee_payment.dart';

class FeeReceiptScreen extends StatelessWidget {
  final StudentFeePayment payment;

  const FeeReceiptScreen({super.key, required this.payment});

  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 6, child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBack.leading(context),title: const Text("Payment Receipt")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Card(
          elevation: 4,

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.school, size: 60, color: Colors.blue),

                      SizedBox(height: 10),

                      Text(
                        SchoolProfileController.instance.name.toUpperCase() + ' ERP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        "OFFICIAL SCHOOL FEE RECEIPT",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                row("Receipt No", payment.receiptNo),

                row("Admission No", payment.admissionNo),

                row("Student Name", payment.studentName),

                row("Class", payment.className),

                row("Session", payment.session),

                row("Term", payment.term),

                row("Payment Date", payment.paymentDate),

                row("Payment Method", payment.paymentMethod),

                const Divider(height: 40),
                row("Tuition Fee", "₦${payment.tuitionFee.toStringAsFixed(0)}"),

                row(
                  "Examination Fee",
                  "₦${payment.examinationFee.toStringAsFixed(0)}",
                ),

                row("ICT Fee", "₦${payment.ictFee.toStringAsFixed(0)}"),

                row("Sport Fee", "₦${payment.sportFee.toStringAsFixed(0)}"),

                row(
                  "Development Levy",
                  "₦${payment.developmentLevy.toStringAsFixed(0)}",
                ),

                row("PTA Fee", "₦${payment.ptaFee.toStringAsFixed(0)}"),

                row(
                  "Other Charges",
                  "₦${payment.otherCharges.toStringAsFixed(0)}",
                ),

                const Divider(height: 40),

                row(
                  "TOTAL SCHOOL FEE",
                  "₦${payment.totalSchoolFee.toStringAsFixed(0)}",
                ),

                row("AMOUNT PAID", "₦${payment.amountPaid.toStringAsFixed(0)}"),
                if (payment.discountAmount > 0.01)
                  row("DISCOUNT", "₦${payment.discountAmount.toStringAsFixed(0)}"),

                row("BALANCE", "₦${payment.balance.toStringAsFixed(0)}"),

                const SizedBox(height: 40),

                const Center(
                  child: Text(
                    "Thank you for your payment.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text("PRINT"),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Printing feature will be added next.",
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.done),
                        label: const Text("DONE"),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

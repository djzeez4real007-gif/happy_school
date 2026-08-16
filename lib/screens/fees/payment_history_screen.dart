import 'package:flutter/material.dart';

import '../../models/student_fee_payment.dart';
import '../../services/student_fee_payment_storage.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<StudentFeePayment> payments = [];
  List<StudentFeePayment> filteredPayments = [];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  Future<void> loadPayments() async {
    payments = await StudentFeePaymentStorage.getPayments();

    filteredPayments = List.from(payments);

    if (mounted) {
      setState(() {});
    }
  }

  void search(String value) {
    if (value.trim().isEmpty) {
      filteredPayments = List.from(payments);
    } else {
      filteredPayments = payments.where((payment) {
        return payment.studentName.toLowerCase().contains(
              value.toLowerCase(),
            ) ||
            payment.admissionNo.toLowerCase().contains(value.toLowerCase()) ||
            payment.receiptNo.toLowerCase().contains(value.toLowerCase()) ||
            payment.className.toLowerCase().contains(value.toLowerCase());
      }).toList();
    }

    setState(() {});
  }

  Future<void> deletePayment(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Payment"),
          content: const Text(
            "Are you sure you want to delete this payment record?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await StudentFeePaymentStorage.deletePayment(index);

    await loadPayments();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment deleted successfully.")),
    );
  }

  Widget buildInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void viewReceipt(StudentFeePayment payment) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Payment Receipt"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildInfo("Receipt No", payment.receiptNo),
                buildInfo("Student", payment.studentName),
                buildInfo("Admission No", payment.admissionNo),
                buildInfo("Class", payment.className),
                buildInfo("Session", payment.session),
                buildInfo("Term", payment.term),

                const Divider(),

                buildInfo(
                  "Tuition Fee",
                  "₦${payment.tuitionFee.toStringAsFixed(0)}",
                ),
                buildInfo(
                  "Examination Fee",
                  "₦${payment.examinationFee.toStringAsFixed(0)}",
                ),
                buildInfo("ICT Fee", "₦${payment.ictFee.toStringAsFixed(0)}"),
                buildInfo(
                  "Sport Fee",
                  "₦${payment.sportFee.toStringAsFixed(0)}",
                ),
                buildInfo(
                  "Development Levy",
                  "₦${payment.developmentLevy.toStringAsFixed(0)}",
                ),
                buildInfo("PTA Fee", "₦${payment.ptaFee.toStringAsFixed(0)}"),
                buildInfo(
                  "Other Charges",
                  "₦${payment.otherCharges.toStringAsFixed(0)}",
                ),

                const Divider(),

                buildInfo(
                  "Total School Fee",
                  "₦${payment.totalSchoolFee.toStringAsFixed(0)}",
                ),
                buildInfo(
                  "Amount Paid",
                  "₦${payment.amountPaid.toStringAsFixed(0)}",
                ),
                buildInfo("Balance", "₦${payment.balance.toStringAsFixed(0)}"),
                buildInfo("Payment Method", payment.paymentMethod),
                buildInfo("Payment Date", payment.paymentDate),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment History")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search Student / Receipt / Admission No",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: search,
            ),

            const SizedBox(height: 20),

            Expanded(
              child: filteredPayments.isEmpty
                  ? const Center(
                      child: Text(
                        "No Payment Record Found",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredPayments.length,
                      itemBuilder: (context, index) {
                        final payment = filteredPayments[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.receipt_long),
                            ),
                            title: Text(payment.studentName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(payment.admissionNo),
                                Text(payment.className),
                                Text(
                                  "Paid: ₦${payment.amountPaid.toStringAsFixed(0)}",
                                ),
                                Text(
                                  "Balance: ₦${payment.balance.toStringAsFixed(0)}",
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == "view") {
                                  viewReceipt(payment);
                                }

                                if (value == "delete") {
                                  final originalIndex = payments.indexOf(
                                    payment,
                                  );

                                  await deletePayment(originalIndex);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: "view",
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 10),
                                      Text("View Receipt"),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

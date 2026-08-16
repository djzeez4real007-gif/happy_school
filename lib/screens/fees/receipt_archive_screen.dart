import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../models/student_fee_payment.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/receipt_pdf_service.dart';

class ReceiptArchiveScreen extends StatefulWidget {
  const ReceiptArchiveScreen({super.key});

  @override
  State<ReceiptArchiveScreen> createState() => _ReceiptArchiveScreenState();
}

class _ReceiptArchiveScreenState extends State<ReceiptArchiveScreen> {
  final TextEditingController searchController = TextEditingController();

  List<StudentFeePayment> receipts = [];
  List<StudentFeePayment> filteredReceipts = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReceipts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================
  // LOAD RECEIPTS
  // ============================
  Future<void> loadReceipts() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    final data = await StudentFeePaymentStorage.getPayments();

    final reversedReceipts = List<StudentFeePayment>.from(data.reversed);

    if (!mounted) return;

    setState(() {
      receipts = reversedReceipts;
      filteredReceipts = List<StudentFeePayment>.from(reversedReceipts);
      loading = false;
    });
  }

  // ============================
  // SEARCH RECEIPTS
  // ============================
  void search(String value) {
    if (!mounted) return;

    final query = value.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredReceipts = List<StudentFeePayment>.from(receipts);
        return;
      }

      filteredReceipts = receipts.where((receipt) {
        return receipt.studentName.toLowerCase().contains(query) ||
            receipt.admissionNo.toLowerCase().contains(query) ||
            receipt.receiptNo.toLowerCase().contains(query);
      }).toList();
    });
  }

  // ============================
  // MONEY FORMAT
  // ============================
  String money(double value) {
    return value.toStringAsFixed(2);
  }

  // ============================
  // PRINT RECEIPT
  // ============================
  Future<void> printReceipt(StudentFeePayment receipt) async {
    try {
      await ReceiptPdfService.printReceipt(receipt);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Printing failed\n$e")));
    }
  }

  // ============================
  // SHARE RECEIPT
  // ============================
  Future<void> shareReceipt(StudentFeePayment receipt) async {
    try {
      await ReceiptPdfService.shareReceipt(receipt);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sharing failed\n$e")));
    }
  }

  // ============================
  // DELETE RECEIPT
  // ============================
  Future<void> deleteReceipt(StudentFeePayment receipt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Receipt"),
          content: Text(
            "Delete receipt ${receipt.receiptNo}?\n\n"
            "This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirm != true) return;

    final originalIndex = receipts.indexOf(receipt);

    if (originalIndex == -1) return;

    await StudentFeePaymentStorage.deletePayment(originalIndex);

    if (!mounted) return;

    await loadReceipts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Receipt deleted successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: const Text("Receipt Archive")),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: searchController,
              onChanged: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Receipt No / Student / Admission No",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredReceipts.isEmpty
                ? const Center(
                    child: Text(
                      "No Receipts Found",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadReceipts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredReceipts.length,
                      itemBuilder: (context, index) {
                        final receipt = filteredReceipts[index];

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ==========================
                                // STUDENT / RECEIPT
                                // ==========================
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 24,
                                      child: Icon(Icons.receipt_long),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            receipt.studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),

                                          Text(
                                            receipt.receiptNo,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(height: 25),

                                // ==========================
                                // ADMISSION NUMBER
                                // ==========================
                                Row(
                                  children: [
                                    const Icon(Icons.badge, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(receipt.admissionNo),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // ==========================
                                // CLASS
                                // ==========================
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.school,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(receipt.className),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // ==========================
                                // PAYMENT DATE
                                // ==========================
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(receipt.paymentDate),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                // ==========================
                                // AMOUNT PAID
                                // ==========================
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Amount Paid",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      "NGN ${money(receipt.amountPaid)}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // ==========================
                                // BALANCE
                                // ==========================
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Balance",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      "NGN ${money(receipt.balance)}",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // ==========================
                                // PRINT / SHARE
                                // ==========================
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.print),
                                        label: const Text("Print"),
                                        onPressed: () {
                                          printReceipt(receipt);
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.share),
                                        label: const Text("Share"),
                                        onPressed: () {
                                          shareReceipt(receipt);
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // ==========================
                                // DELETE
                                // ==========================
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          "Delete Receipt",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () {
                                          deleteReceipt(receipt);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

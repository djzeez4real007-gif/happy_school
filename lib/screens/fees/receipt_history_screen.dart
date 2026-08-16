import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../models/student_fee_payment.dart';
import '../../services/audit_log_storage.dart';
import '../../services/student_fee_payment_storage.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  State<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  List<StudentFeePayment> receipts = [];

  @override
  void initState() {
    super.initState();
    loadReceipts();
  }

  Future<void> loadReceipts() async {
    receipts = await StudentFeePaymentStorage.getPayments();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteReceipt(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: const Text(
          'This cannot be undone. The payment record will be removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await StudentFeePaymentStorage.deletePayment(index);
    await AuditLogStorage.log(
      action: 'receipt_deleted',
      module: 'fees',
      description: 'Deleted a fee receipt',
    );
    await loadReceipts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text("Receipt History (${receipts.length})")),

      body: receipts.isEmpty
          ? const Center(child: Text("No Receipts Found"))
          : ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  child: ListTile(
                    leading: CircleAvatar(child: Text("${index + 1}")),

                    title: Text(
                      receipt.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Receipt: ${receipt.receiptNo}"),
                        Text("Class: ${receipt.className}"),
                        Text(
                          "Paid: NGN ${receipt.amountPaid.toStringAsFixed(2)}",
                        ),
                        Text(
                          "Balance: NGN ${receipt.balance.toStringAsFixed(2)}",
                        ),
                        Text(receipt.paymentDate),
                      ],
                    ),

                    isThreeLine: true,

                    trailing: PopupMenuButton(
                      onSelected: (value) async {
                        if (value == "delete") {
                          await deleteReceipt(index);
                        }

                        if (value == "print") {
                          // We'll connect PDF printing next.
                        }
                      },

                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "print", child: Text("Print")),

                        PopupMenuItem(value: "delete", child: Text("Delete")),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

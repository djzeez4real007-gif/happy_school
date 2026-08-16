// lib/screens/fees/financial_reports_screen.dart

import 'package:flutter/material.dart';

import '../../core/utils/sessions.dart';

import '../../models/student_fee_payment.dart';
import '../../services/student_fee_payment_storage.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  List<StudentFeePayment> payments = [];

  bool loading = true;

  String selectedSession = "All";
  String selectedTerm = "All";
  String selectedClass = "All";

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  // =========================================================
  // LOAD ALL PAYMENT RECORDS
  // =========================================================

  Future<void> loadReports() async {
    setState(() {
      loading = true;
    });

    try {
      final data = await StudentFeePaymentStorage.getPayments();

      if (!mounted) return;

      setState(() {
        payments = data.cast<StudentFeePayment>();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to load financial records: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // FILTERED PAYMENTS
  // =========================================================

  List<StudentFeePayment> get filteredPayments {
    return payments.where((payment) {
      final sessionMatches =
          selectedSession == "All" || payment.session == selectedSession;

      final termMatches = selectedTerm == "All" || payment.term == selectedTerm;

      final classMatches =
          selectedClass == "All" || payment.className == selectedClass;

      return sessionMatches && termMatches && classMatches;
    }).toList();
  }

  // =========================================================
  // TOTAL SCHOOL FEES
  // =========================================================

  /// Expected school fees for filtered set:
  /// unique students × their class fee (from payment snapshot), not sum of every receipt.
  double get totalSchoolFees {
    final byStudent = <String, double>{};
    for (final payment in filteredPayments) {
      // Keep the max totalSchoolFee seen for that student (one fee structure)
      final prev = byStudent[payment.admissionNo] ?? 0;
      if (payment.totalSchoolFee > prev) {
        byStudent[payment.admissionNo] = payment.totalSchoolFee;
      }
    }
    return byStudent.values.fold<double>(0, (a, b) => a + b);
  }

  // =========================================================
  // TOTAL AMOUNT COLLECTED
  // =========================================================

  double get totalCollected {
    double total = 0;

    for (final payment in filteredPayments) {
      total += payment.amountPaid;
    }

    return total;
  }

  // =========================================================
  // TOTAL OUTSTANDING BALANCE
  // =========================================================

  double get totalBalance {
    double total = 0;

    for (final payment in filteredPayments) {
      total += payment.balance;
    }

    return total;
  }

  // =========================================================
  // TOTAL TRANSACTIONS
  // =========================================================

  int get totalTransactions {
    return filteredPayments.length;
  }

  // =========================================================
  // MONEY FORMAT
  // =========================================================

  String money(double amount) {
    return "₦${amount.toStringAsFixed(2)}";
  }

  // =========================================================
  // AVAILABLE SESSIONS
  // =========================================================

  List<String> get sessions {
    final values = {
      ...Sessions.list(),
      ...payments
          .map((payment) => payment.session)
          .where((value) => value.isNotEmpty),
    }.toList();

    values.sort();

    return ["All", ...values];
  }

  // =========================================================
  // AVAILABLE TERMS
  // =========================================================

  List<String> get terms {
    final values = payments
        .map((payment) => payment.term)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    return ["All", ...values];
  }

  // =========================================================
  // AVAILABLE CLASSES
  // =========================================================

  List<String> get classes {
    final values = payments
        .map((payment) => payment.className)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    values.sort();

    return ["All", ...values];
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 28),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FILTER DROPDOWN
  // =========================================================

  Widget filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : "All";

    return Expanded(
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // =========================================================
  // PAYMENT DETAIL
  // =========================================================

  Widget detailItem(String title, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),

            const SizedBox(height: 4),

            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PAYMENT CARD
  // =========================================================

  Widget paymentCard(StudentFeePayment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        payment.admissionNo,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  money(payment.amountPaid),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            Row(
              children: [
                detailItem("Class", payment.className),
                detailItem("Session", payment.session),
                detailItem("Term", payment.term),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                detailItem("Total Fee", money(payment.totalSchoolFee)),
                detailItem("Paid", money(payment.amountPaid)),
                detailItem("Balance", money(payment.balance)),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Receipt: ${payment.receiptNo}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),

            const SizedBox(height: 4),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Payment Method: ${payment.paymentMethod}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CLEAR FILTERS
  // =========================================================

  void clearFilters() {
    setState(() {
      selectedSession = "All";
      selectedTerm = "All";
      selectedClass = "All";
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final filtered = filteredPayments;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          "Financial Reports",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: loadReports,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadReports,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                children: [
                  // =================================================
                  // PAGE HEADER
                  // =================================================
                  const Text(
                    "Financial Overview",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Monitor school fees, payments and outstanding balances.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // SUMMARY CARDS
                  // =================================================
                  summaryCard(
                    title: "Total School Fees",
                    value: money(totalSchoolFees),
                    icon: Icons.account_balance_wallet,
                    color: Colors.blue,
                  ),

                  summaryCard(
                    title: "Total Collected",
                    value: money(totalCollected),
                    icon: Icons.payments,
                    color: Colors.green,
                  ),

                  summaryCard(
                    title: "Outstanding Balance",
                    value: money(totalBalance),
                    icon: Icons.warning_amber,
                    color: Colors.red,
                  ),

                  summaryCard(
                    title: "Payment Transactions",
                    value: totalTransactions.toString(),
                    icon: Icons.receipt_long,
                    color: Colors.deepPurple,
                  ),

                  const SizedBox(height: 10),

                  // =================================================
                  // FILTERS
                  // =================================================
                  Card(
                    elevation: 1,

                    child: Padding(
                      padding: const EdgeInsets.all(14),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            "REPORT FILTERS",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Row(
                            children: [
                              filterDropdown(
                                label: "Session",
                                value: selectedSession,
                                items: sessions,
                                onChanged: (value) {
                                  setState(() {
                                    selectedSession = value ?? "All";
                                  });
                                },
                              ),

                              const SizedBox(width: 10),

                              filterDropdown(
                                label: "Term",
                                value: selectedTerm,
                                items: terms,
                                onChanged: (value) {
                                  setState(() {
                                    selectedTerm = value ?? "All";
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              filterDropdown(
                                label: "Class",
                                value: selectedClass,
                                items: classes,
                                onChanged: (value) {
                                  setState(() {
                                    selectedClass = value ?? "All";
                                  });
                                },
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: clearFilters,
                                  icon: const Icon(Icons.clear),
                                  label: const Text("Clear Filters"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // PAYMENT RECORDS HEADER
                  // =================================================
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Payment Records",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${filtered.length} record${filtered.length == 1 ? '' : 's'}",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // RECORDS
                  // =================================================
                  if (filtered.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(35),

                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              "No payment records found.",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map(paymentCard),
                ],
              ),
            ),
    );
  }
}

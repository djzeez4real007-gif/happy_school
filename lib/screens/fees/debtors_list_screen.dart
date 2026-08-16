import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../models/student.dart';
import '../../models/school_fee.dart';
import '../../services/student_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/school_fee_storage.dart';

class DebtorsListScreen extends StatefulWidget {
  const DebtorsListScreen({super.key});

  @override
  State<DebtorsListScreen> createState() => _DebtorsListScreenState();
}

class _DebtorsListScreenState extends State<DebtorsListScreen> {
  bool loading = true;

  List<Map<String, dynamic>> debtors = [];

  @override
  void initState() {
    super.initState();
    loadDebtors();
  }

  Future<void> loadDebtors() async {
    loading = true;

    if (mounted) {
      setState(() {});
    }

    debtors.clear();

    final students = await StudentStorage.getStudents();

    final classAssignments = await StudentClassStorage.getStudents();

    for (final student in students) {
      try {
        final studentClass = classAssignments.firstWhere(
          (e) => e.admissionNo == student.admissionNo,
        );

        final term = studentClass.term.isNotEmpty
            ? studentClass.term
            : 'First Term';
        final session = studentClass.session.isNotEmpty
            ? studentClass.session
            : '2026/2027';
        final SchoolFee? schoolFee = await SchoolFeeStorage.getFee(
          studentClass.className,
          session,
          term,
        );

        if (schoolFee == null) {
          continue;
        }

        final paid = await StudentFeePaymentStorage.totalPaid(
          student.admissionNo,
        );

        final balance = schoolFee.totalFee - paid;

        if (balance > 0) {
          debtors.add({
            "student": student,
            "class": studentClass.className,
            "session": studentClass.session,
            "term": studentClass.term,
            "totalFee": schoolFee.totalFee,
            "amountPaid": paid,
            "balance": balance,
          });
        }
      } catch (_) {
        // Student not assigned to a class
      }
    }

    debtors.sort(
      (a, b) => (b["balance"] as double).compareTo(a["balance"] as double),
    );

    loading = false;

    if (mounted) {
      setState(() {});
    }
  }

  String money(double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text("Debtors (${debtors.length})")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : debtors.isEmpty
          ? const Center(
              child: Text("No Debtors Found", style: TextStyle(fontSize: 18)),
            )
          : RefreshIndicator(
              onRefresh: loadDebtors,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: debtors.length,
                itemBuilder: (context, index) {
                  final item = debtors[index];

                  final Student student = item["student"] as Student;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                child: Icon(Icons.person),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),

                                    Text(
                                      student.admissionNo,
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

                          Row(
                            children: [
                              const Icon(Icons.school, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(item["class"]),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text("${item["session"]}  •  ${item["term"]}"),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "School Fee",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text("NGN ${money(item["totalFee"])}"),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Paid",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "NGN ${money(item["amountPaid"])}",
                                style: const TextStyle(color: Colors.green),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Outstanding",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "NGN ${money(item["balance"])}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.payments),
                                  label: const Text("Receive Payment"),
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
                  );
                },
              ),
            ),
    );
  }
}

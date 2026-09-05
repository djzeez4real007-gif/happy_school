import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';

import '../../core/theme/app_colors.dart';
import '../../models/student.dart';
import '../../models/student_fee_payment.dart';
import '../../services/student_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import 'receipt_screen.dart';

class StudentPaymentHistoryScreen extends StatefulWidget {
  final String? admissionNo;

  const StudentPaymentHistoryScreen({super.key, this.admissionNo});

  @override
  State<StudentPaymentHistoryScreen> createState() =>
      _StudentPaymentHistoryScreenState();
}

class _StudentPaymentHistoryScreenState
    extends State<StudentPaymentHistoryScreen> {
  List<Student> students = [];
  Student? selected;
  List<StudentFeePayment> payments = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    students = await StudentStorage.getStudents();
    students.sort((a, b) => a.fullName.compareTo(b.fullName));
    if (widget.admissionNo != null) {
      try {
        selected =
            students.firstWhere((s) => s.admissionNo == widget.admissionNo);
        await _loadPayments();
      } catch (_) {}
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadPayments() async {
    if (selected == null) return;
    payments = await StudentFeePaymentStorage.getStudentPayments(
      selected!.admissionNo,
    );
    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    if (mounted) setState(() {});
  }

  List<Student> get filteredStudents {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return students;
    return students
        .where((s) =>
            s.fullName.toLowerCase().contains(q) ||
            s.admissionNo.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        leading: AppBack.leading(context),
        title: const Text('Student Payments'),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0E7490), Color(0xFF06B6D4)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment history by student',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Search name or admission no…',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() => searchQuery = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: selected == null
                      ? ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final s = filteredStudents[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.cardBorder(context),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF0E7490),
                                  child: Text(
                                    s.firstName.isNotEmpty
                                        ? s.firstName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  s.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(s.admissionNo),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  selected = s;
                                  await _loadPayments();
                                },
                              ),
                            );
                          },
                        )
                      : Column(
                          children: [
                            ListTile(
                              leading: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => setState(() {
                                  selected = null;
                                  payments = [];
                                }),
                              ),
                              title: Text(
                                selected!.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                '${selected!.admissionNo} · ${payments.length} receipt(s)',
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: payments.isEmpty
                                  ? const Center(
                                      child: Text('No payments for this student'),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: payments.length,
                                      itemBuilder: (context, index) {
                                        final p = payments[index];
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.card(context),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: AppColors.cardBorder(
                                                  context),
                                            ),
                                          ),
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.receipt_long,
                                              color: Color(0xFF059669),
                                            ),
                                            title: Text(
                                              p.receiptNo,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800),
                                            ),
                                            subtitle: Text(
                                              [
                                                if (p.session.trim().isNotEmpty ||
                                                    p.term.trim().isNotEmpty)
                                                  [
                                                    if (p.session.trim().isNotEmpty)
                                                      p.session.trim(),
                                                    if (p.term.trim().isNotEmpty)
                                                      p.term.trim(),
                                                  ].join(' · '),
                                                p.paymentDate,
                                                '${p.paymentMethod} · Bal ₦${p.balance.toStringAsFixed(0)}',
                                              ].join('\n'),
                                            ),
                                            isThreeLine: true,
                                            trailing: Text(
                                              '₦${p.amountPaid.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF059669),
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ReceiptScreen(
                                                          payment: p),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

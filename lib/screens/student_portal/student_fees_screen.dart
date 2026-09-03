import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/student_fee_payment.dart';
import '../../services/auth_service.dart';
import '../../services/student_fee_payment_storage.dart';

class StudentFeesScreen extends StatefulWidget {
  const StudentFeesScreen({super.key});

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen> {
  bool loading = true;
  List<StudentFeePayment> payments = [];
  double total = 0;
  String? error;

  String get admissionNo {
    final u = AuthService.currentUser;
    if (u == null) return '';
    final linked = u.childrenAdmissionNos;
    if (linked.isNotEmpty) return linked.first;
    return u.username;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final adm = admissionNo.trim();
    try {
      List<StudentFeePayment> list = [];
      try {
        list = await StudentFeePaymentStorage.getStudentPayments(adm);
      } catch (_) {
        final all = await StudentFeePaymentStorage.getPayments();
        list = all
            .where((p) =>
                p.admissionNo.trim().toLowerCase() == adm.toLowerCase())
            .toList();
      }
      if (list.isEmpty) {
        final all = await StudentFeePaymentStorage.getPayments();
        list = all
            .where((p) =>
                p.admissionNo.trim().toLowerCase() == adm.toLowerCase())
            .toList();
      }
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      double sum = 0;
      try {
        sum = await StudentFeePaymentStorage.totalPaid(adm);
      } catch (_) {
        for (final p in list) {
          sum += p.amountPaid;
        }
      }
      if (!mounted) return;
      setState(() {
        payments = list;
        total = sum;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('My fees'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total paid',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '₦${fmt.format(total)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                          ),
                        ),
                        Text(
                          'Admission: $admissionNo',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (payments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder(context)),
                      ),
                      child: const Text(
                        'No payments recorded for your admission number yet.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...payments.map((p) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          title: Text(
                            '₦${fmt.format(p.amountPaid)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${p.session} · ${p.term}\n'
                            '${p.paymentDate} · ${p.paymentMethod}\n'
                            'Receipt: ${p.receiptNo}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

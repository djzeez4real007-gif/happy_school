import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../models/student_fee_payment.dart';
import '../../models/result.dart';
import '../../services/auth_service.dart';
import '../../services/student_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/result_storage.dart';

class ParentPortalScreen extends StatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  bool loading = true;
  List<_ChildBundle> children = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AuthService.currentUser;
    final nos = user?.childrenAdmissionNos ?? [];
    final bundles = <_ChildBundle>[];
    final all = await StudentStorage.getStudents();

    // Normalize admission numbers so HSC/2026/002 matches HSC/2026/0002
    String norm(String v) {
      final s = v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
      // Collapse leading zeros in the last numeric segment
      final parts = s.split('/');
      if (parts.isEmpty) return s;
      final last = parts.last.replaceFirst(RegExp(r'^0+'), '');
      parts[parts.length - 1] = last.isEmpty ? '0' : last;
      return parts.join('/');
    }

    Student? findStudent(String no) {
      final target = norm(no);
      final exact = no.trim();
      for (final s in all) {
        final adm = s.admissionNo.trim();
        if (adm == exact) return s;
        if (norm(adm) == target) return s;
        // Also allow suffix match on the numeric id only
        if (adm.toLowerCase().endsWith(exact.toLowerCase()) ||
            exact.toLowerCase().endsWith(adm.toLowerCase())) {
          return s;
        }
      }
      return null;
    }

    for (final no in nos) {
      final student = findStudent(no);
      if (student == null) continue;

      final sc = await StudentClassStorage.getStudent(no);
      final paid = await StudentFeePaymentStorage.totalPaid(no);
      List<StudentFeePayment> payments = [];
      try {
        payments = await StudentFeePaymentStorage.getStudentPayments(no);
      } catch (_) {
        payments = [];
      }
      double balance = 0;
      if (payments.isNotEmpty) {
        payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        balance = payments.first.balance;
      }
      List<Result> results = [];
      try {
        results = await ResultStorage.getStudentResults(no);
      } catch (_) {}

      bundles.add(_ChildBundle(
        student: student,
        studentClass: sc,
        totalPaid: paid,
        balance: balance,
        results: results,
        payments: payments,
      ));
    }

    if (!mounted) return;
    setState(() {
      children = bundles;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
            body: loading
          ? const Center(child: CircularProgressIndicator())
          : children.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      (AuthService.currentUser?.childrenAdmissionNos.isEmpty ??
                              true)
                          ? 'No children linked.\n'
                              'Edit this parent user and enter admission numbers separated by commas.\n'
                              'Example: HSC/2026/0001, HSC/2026/0002'
                          : 'Linked: ${AuthService.currentUser?.linkedAdmissionNos ?? ""}\n'
                              'but no matching students were found. Check the numbers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final c = children[index];
                    final owing = c.balance > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder(context)),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1D4ED8),
                          child: Text(
                            c.student.firstName.isNotEmpty
                                ? c.student.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          c.student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${c.student.admissionNo}'
                          '${c.studentClass != null ? ' · ${c.studentClass!.className}' : ''}',
                        ),
                        children: [
                          ListTile(
                            leading: Icon(
                              owing
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle,
                              color: owing ? Colors.orange : Colors.green,
                            ),
                            title: Text(
                                owing ? 'Fees outstanding' : 'Fees up to date'),
                            subtitle: Text(
                              owing
                                  ? 'Balance: ₦${c.balance.toStringAsFixed(0)}'
                                  : 'Total paid: ₦${c.totalPaid.toStringAsFixed(0)}',
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.grade_rounded),
                            title: const Text('Results recorded'),
                            subtitle:
                                Text('${c.results.length} result line(s)'),
                          ),
                          ...c.results.take(10).map(
                                (r) => ListTile(
                                  dense: true,
                                  title: Text(r.subjectName),
                                  subtitle: Text('${r.term} · ${r.session}'),
                                  trailing: Text(
                                    '${r.total}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                          if (c.payments.isNotEmpty) ...[
                            const Divider(height: 1),
                            const ListTile(
                              title: Text('Payment receipts'),
                              dense: true,
                            ),
                            ...c.payments.map(
                              (p) => ListTile(
                                dense: true,
                                title: Text(p.receiptNo),
                                subtitle: Text(
                                    '${p.paymentDate} · ${p.paymentMethod}'),
                                trailing: Text(
                                  '₦${p.amountPaid.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _ChildBundle {
  final Student student;
  final StudentClass? studentClass;
  final double totalPaid;
  final double balance;
  final List<Result> results;
  final List<StudentFeePayment> payments;

  _ChildBundle({
    required this.student,
    required this.studentClass,
    required this.totalPaid,
    required this.balance,
    required this.results,
    required this.payments,
  });
}

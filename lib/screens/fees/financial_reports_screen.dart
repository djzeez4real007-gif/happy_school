import 'package:flutter/material.dart';

import '../../core/utils/sessions.dart';
import '../../models/student_fee_payment.dart';
import '../../services/school_fee_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/student_storage.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  List<StudentFeePayment> payments = [];
  bool loading = true;

  String selectedSession = Sessions.current();
  String selectedTerm = 'First Term';
  String selectedClass = 'All';

  // Enrollment-based totals (correct maths)
  double expectedFees = 0;
  double collectedAmount = 0;
  double outstandingAmount = 0;
  int debtorCount = 0;
  int studentCountWithFee = 0;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    setState(() => loading = true);

    try {
      final data = await StudentFeePaymentStorage.getPayments();
      payments = data;
      await _recalculateTotals();
      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load financial records: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Correct formula:
  /// For each assigned student with a fee for session+term (+ optional class filter):
  ///   expected += fee
  ///   paid = sum of payments for that student/session/term
  ///   outstanding += max(0, fee - paid)
  ///   collected += min(paid, fee)  (or just sum of payments — same for totals)
  Future<void> _recalculateTotals() async {
    final students = await StudentStorage.getStudents();
    final assignments = await StudentClassStorage.getStudents();

    double expected = 0;
    double collected = 0;
    double outstanding = 0;
    int debtors = 0;
    int withFee = 0;

    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

    bool classMatches(String studentClass, String filter) {
      if (filter == 'All') return true;
      final a = norm(studentClass);
      final b = norm(filter);
      return a == b || a.startsWith(b) || b.startsWith(a);
    }

    for (final student in students) {
      try {
        final adm = student.admissionNo.trim().toLowerCase();
        final matches = assignments
            .where(
              (e) =>
                  e.admissionNo.trim().toLowerCase() == adm &&
                  e.session.trim() == selectedSession.trim(),
            )
            .toList();
        if (matches.isEmpty) continue;
        final sc = matches.last;
        final cls = sc.className.trim().toLowerCase();
        if (cls == 'graduated' || cls == 'left' || cls == 'withdrawn') {
          continue;
        }
        if (!classMatches(sc.className, selectedClass)) continue;

        final fee = await SchoolFeeStorage.getFee(
          sc.className,
          selectedSession,
          selectedTerm,
        );
        if (fee == null) continue;

        withFee++;
        expected += fee.totalFee;

        final paid = await StudentFeePaymentStorage.totalPaidForTerm(
          student.admissionNo,
          session: selectedSession,
          term: selectedTerm,
        );

        collected += paid > fee.totalFee ? fee.totalFee : paid;
        final bal = fee.totalFee - paid;
        if (bal > 0.01) {
          debtors++;
          outstanding += bal;
        }
      } catch (_) {
        // not assigned
      }
    }

    expectedFees = expected;
    collectedAmount = collected;
    outstandingAmount = outstanding;
    debtorCount = debtors;
    studentCountWithFee = withFee;
  }

  List<StudentFeePayment> get filteredPayments {
    return payments.where((payment) {
      final sessionMatches = payment.session == selectedSession;
      final termMatches = payment.term == selectedTerm;
      final classMatches =
          selectedClass == 'All' || payment.className == selectedClass;
      return sessionMatches && termMatches && classMatches;
    }).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  int get totalTransactions => filteredPayments.length;

  String money(double amount) => '₦${amount.toStringAsFixed(2)}';

  List<String> get sessions {
    final values = {
      ...Sessions.list(),
      ...payments.map((p) => p.session).where((v) => v.isNotEmpty),
    }.toList()
      ..sort();
    return values;
  }

  List<String> get terms => List<String>.from(Sessions.terms);

  List<String> get classOptions {
    final values = payments
        .map((p) => p.className)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      return '$d/$m/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Widget summaryCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentCard(StudentFeePayment p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.studentName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                money(p.amountPaid),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${p.receiptNo} · ${p.className}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
          Text(
            '${p.session} · ${p.term} · ${_formatDate(p.paymentDate)}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _onFilterChanged() async {
    setState(() => loading = true);
    await _recalculateTotals();
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredPayments;
    final pct = expectedFees <= 0
        ? 0.0
        : ((collectedAmount / expectedFees) * 100).clamp(0.0, 100.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  const Text(
                    'Financial Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expected fees for assigned students · $selectedSession · $selectedTerm',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),

                  // Filters
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REPORT FILTERS',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: sessions.contains(selectedSession)
                                    ? selectedSession
                                    : sessions.first,
                                decoration:
                                    const InputDecoration(labelText: 'Session'),
                                items: sessions
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (v) async {
                                  if (v == null) return;
                                  selectedSession = v;
                                  await _onFilterChanged();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedTerm,
                                decoration:
                                    const InputDecoration(labelText: 'Term'),
                                items: terms
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (v) async {
                                  if (v == null) return;
                                  selectedTerm = v;
                                  await _onFilterChanged();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: classOptions.contains(selectedClass)
                              ? selectedClass
                              : 'All',
                          decoration:
                              const InputDecoration(labelText: 'Class'),
                          items: classOptions
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ))
                              .toList(),
                          onChanged: (v) async {
                            if (v == null) return;
                            selectedClass = v;
                            await _onFilterChanged();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  summaryCard(
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF2563EB),
                    title: 'Total School Fees (expected)',
                    value: money(expectedFees),
                  ),
                  summaryCard(
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF059669),
                    title: 'Total Collected',
                    value: money(collectedAmount),
                  ),
                  summaryCard(
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFDC2626),
                    title: 'Outstanding Balance',
                    value: money(outstandingAmount),
                  ),
                  summaryCard(
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF7C3AED),
                    title: 'Payment Transactions',
                    value: '$totalTransactions',
                  ),
                  summaryCard(
                    icon: Icons.groups_rounded,
                    color: const Color(0xFFEA580C),
                    title: 'Students with fee / Debtors',
                    value: '$studentCountWithFee / $debtorCount',
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection progress · ${pct.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Expected = assigned students × class fee for this session/term.\n'
                          'Outstanding = expected − collected (includes unpaid students).',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Payment Records',
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
                          '${filtered.length} record${filtered.length == 1 ? '' : 's'}',
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
                              'No payment records for this filter.',
                              style: TextStyle(color: Colors.grey.shade600),
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

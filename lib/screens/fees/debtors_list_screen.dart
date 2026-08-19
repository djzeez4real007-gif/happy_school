import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../models/student.dart';
import '../../models/school_fee.dart';
import '../../services/student_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/school_fee_storage.dart';
import 'student_fee_payment_screen.dart';

class DebtorsListScreen extends StatefulWidget {
  const DebtorsListScreen({super.key});

  @override
  State<DebtorsListScreen> createState() => _DebtorsListScreenState();
}

class _DebtorsListScreenState extends State<DebtorsListScreen> {
  bool loading = true;
  List<Map<String, dynamic>> debtors = [];
  String query = '';
  String selectedSession = Sessions.current();
  String selectedTerm = 'First Term';
  final sessions = Sessions.list();
  final terms = Sessions.terms;

  @override
  void initState() {
    super.initState();
    loadDebtors();
  }

  Future<void> loadDebtors() async {
    setState(() => loading = true);
    final list = <Map<String, dynamic>>[];

    final students = await StudentStorage.getStudents();
    final classAssignments = await StudentClassStorage.getStudents();

    for (final student in students) {
      try {
        final adm = student.admissionNo.trim().toLowerCase();
        final matches = classAssignments
            .where(
              (e) =>
                  e.admissionNo.trim().toLowerCase() == adm &&
                  e.session.trim() == selectedSession.trim(),
            )
            .toList();
        if (matches.isEmpty) continue;
        final studentClass = matches.last;
        final cls = studentClass.className.trim().toLowerCase();
        if (cls == 'graduated' || cls == 'left' || cls == 'withdrawn') {
          continue;
        }

        final SchoolFee? schoolFee = await SchoolFeeStorage.getFee(
          studentClass.className,
          selectedSession,
          selectedTerm,
        );
        if (schoolFee == null) continue;

        final paid = await StudentFeePaymentStorage.totalPaidForTerm(
          student.admissionNo,
          session: selectedSession,
          term: selectedTerm,
        );

        final balance = schoolFee.totalFee - paid;
        if (balance > 0.01) {
          list.add({
            'student': student,
            'class': studentClass.className,
            'session': selectedSession,
            'term': selectedTerm,
            'totalFee': schoolFee.totalFee,
            'amountPaid': paid,
            'balance': balance,
          });
        }
      } catch (_) {
        // not assigned
      }
    }

    list.sort(
      (a, b) => (b['balance'] as double).compareTo(a['balance'] as double),
    );

    if (!mounted) return;
    setState(() {
      debtors = list;
      loading = false;
    });
  }

  List<Map<String, dynamic>> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return debtors;
    return debtors.where((item) {
      final student = item['student'] as Student;
      return student.fullName.toLowerCase().contains(q) ||
          student.admissionNo.toLowerCase().contains(q) ||
          '${item['class']}'.toLowerCase().contains(q);
    }).toList();
  }

  String money(double value) =>
      '₦${value.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )}';

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    final totalOutstanding = list.fold<double>(
      0,
      (sum, e) => sum + (e['balance'] as double),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Debtors',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${list.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Outstanding: ${money(totalOutstanding)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Search name, admission no, class…',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _headerDropdown(
                          value: sessions.contains(selectedSession)
                              ? selectedSession
                              : sessions.first,
                          items: sessions,
                          onChanged: (v) {
                            if (v == null) return;
                            selectedSession = v;
                            loadDebtors();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _headerDropdown(
                          value: selectedTerm,
                          items: terms,
                          onChanged: (v) {
                            if (v == null) return;
                            selectedTerm = v;
                            loadDebtors();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              query.isEmpty
                                  ? 'No debtors for $selectedTerm'
                                  : 'No matches for “$query”',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadDebtors,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final student = item['student'] as Student;
                            final totalFee = item['totalFee'] as double;
                            final paid = item['amountPaid'] as double;
                            final balance = item['balance'] as double;
                            final progress =
                                totalFee <= 0 ? 0.0 : (paid / totalFee).clamp(0.0, 1.0);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.cardBorder(context),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFDC2626),
                                                Color(0xFFF97316),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            student.firstName.isNotEmpty
                                                ? student.firstName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.fullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                student.admissionNo,
                                                style: TextStyle(
                                                  color: AppColors
                                                      .textSecondary(context),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          money(balance),
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _chip(
                                          '${item['class']}',
                                          const Color(0xFFEFF6FF),
                                          const Color(0xFF1D4ED8),
                                        ),
                                        _chip(
                                          '${item['session']}',
                                          const Color(0xFFF5F3FF),
                                          const Color(0xFF6D28D9),
                                        ),
                                        _chip(
                                          '${item['term']}',
                                          const Color(0xFFECFDF5),
                                          const Color(0xFF047857),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 7,
                                        backgroundColor:
                                            const Color(0xFFFEE2E2),
                                        color: progress > 0.6
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFDC2626),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Fee ${money(totalFee)}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.textSecondary(
                                                  context),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Paid ${money(paid)}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const StudentFeePaymentScreen(),
                                            ),
                                          );
                                          await loadDebtors();
                                        },
                                        icon: const Icon(
                                          Icons.payments_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Receive Payment',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1D4ED8),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
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

  Widget _headerDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF7F1D1D),
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

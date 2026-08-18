import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../models/school_class.dart';
import '../../models/student.dart';
import '../../services/class_storage.dart';
import '../../services/school_fee_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/student_storage.dart';

/// Tabular paid / unpaid status for accountants.
/// Uses current class assignment (includes promoted students).
class FeePaymentStatusScreen extends StatefulWidget {
  const FeePaymentStatusScreen({super.key});

  @override
  State<FeePaymentStatusScreen> createState() => _FeePaymentStatusScreenState();
}

class _FeePaymentStatusScreenState extends State<FeePaymentStatusScreen> {
  bool loading = true;
  String selectedSession = Sessions.current();
  String selectedTerm = 'First Term';
  String selectedClass = 'All';
  String query = '';
  String statusFilter = 'All'; // All | Paid | Partial | Unpaid

  final sessions = Sessions.list();
  final terms = Sessions.terms;
  List<SchoolClass> classes = [];
  List<_StatusRow> rows = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    classes = await ClassStorage.getClasses();
    classes.sort(
      (a, b) => a.fullClassName.toLowerCase().compareTo(
            b.fullClassName.toLowerCase(),
          ),
    );

    // Prefer a session that actually has class assignments (not empty year)
    final assignments = await StudentClassStorage.getStudents();
    if (assignments.isNotEmpty) {
      final counts = <String, int>{};
      for (final a in assignments) {
        final s = a.session.trim();
        if (s.isEmpty) continue;
        counts[s] = (counts[s] ?? 0) + 1;
      }
      if (counts.isNotEmpty) {
        final best = counts.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
        );
        selectedSession = best.key;
      }
    }

    await loadRows();
  }

  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

  bool _classMatches(String studentClass, String selected) {
    if (selected == 'All') return true;
    final a = _norm(studentClass);
    final b = _norm(selected);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    return a.startsWith(b) || b.startsWith(a);
  }

  Future<void> loadRows() async {
    setState(() => loading = true);

    final students = await StudentStorage.getStudents();
    final assignments = await StudentClassStorage.getStudents();
    final list = <_StatusRow>[];

    for (final student in students) {
      try {
        final adm = student.admissionNo.trim().toLowerCase();
        // Latest assignment for this session (promoted / repeated class)
        final matches = assignments
            .where(
              (a) =>
                  a.admissionNo.trim().toLowerCase() == adm &&
                  a.session.trim() == selectedSession.trim(),
            )
            .toList();
        if (matches.isEmpty) continue;

        final sc = matches.last;
        final className = sc.className;

        if (!_classMatches(className, selectedClass)) continue;

        final fee = await SchoolFeeStorage.getFee(
          className,
          selectedSession,
          selectedTerm,
        );

        final paid = await StudentFeePaymentStorage.totalPaidForTerm(
          student.admissionNo,
          session: selectedSession,
          term: selectedTerm,
        );

        final totalFee = fee?.totalFee ?? 0;
        final balance = fee == null ? 0.0 : totalFee - paid;

        String status;
        if (fee == null) {
          status = 'No fee';
        } else if (paid <= 0.01) {
          status = 'Unpaid';
        } else if (balance <= 0.01) {
          status = 'Paid';
        } else {
          status = 'Partial';
        }

        list.add(
          _StatusRow(
            student: student,
            className: className,
            totalFee: totalFee,
            paid: paid,
            balance: balance,
            status: status,
          ),
        );
      } catch (_) {}
    }

    list.sort((a, b) {
      final c = a.className.compareTo(b.className);
      if (c != 0) return c;
      return a.student.fullName.compareTo(b.student.fullName);
    });

    if (!mounted) return;
    setState(() {
      rows = list;
      loading = false;
    });
  }

  List<_StatusRow> get filtered {
    return rows.where((r) {
      if (statusFilter != 'All' && r.status != statusFilter) return false;
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.student.fullName.toLowerCase().contains(q) ||
          r.student.admissionNo.toLowerCase().contains(q) ||
          r.className.toLowerCase().contains(q);
    }).toList();
  }

  String money(double v) =>
      '₦${v.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )}';

  Color _statusColor(String s) {
    switch (s) {
      case 'Paid':
        return const Color(0xFF059669);
      case 'Partial':
        return const Color(0xFFD97706);
      case 'No fee':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    final paidCount = list.where((e) => e.status == 'Paid').length;
    final unpaidCount = list.where((e) => e.status == 'Unpaid').length;
    final partialCount = list.where((e) => e.status == 'Partial').length;

    final classNames = [
      'All',
      ...classes.map((c) => c.fullClassName).toSet(),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
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
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
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
                        'Payment Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: loadRows,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Paid $paidCount · Partial $partialCount · Unpaid $unpaidCount',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
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
                        child: _dd(
                          value: sessions.contains(selectedSession)
                              ? selectedSession
                              : sessions.first,
                          items: sessions,
                          onChanged: (v) async {
                            if (v == null) return;
                            selectedSession = v;
                            await loadRows();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dd(
                          value: selectedTerm,
                          items: terms,
                          onChanged: (v) async {
                            if (v == null) return;
                            selectedTerm = v;
                            await loadRows();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _dd(
                          value: classNames.contains(selectedClass)
                              ? selectedClass
                              : 'All',
                          items: classNames,
                          onChanged: (v) async {
                            if (v == null) return;
                            selectedClass = v;
                            await loadRows();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dd(
                          value: statusFilter,
                          items: const ['All', 'Paid', 'Partial', 'Unpaid', 'No fee'],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => statusFilter = v);
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
                        child: Text(
                          'No students for this filter.\n\n'
                          '• Pick the session where students are assigned\n'
                          '  (e.g. 2026/2027)\n'
                          '• Status filter: use All to see everyone\n'
                          '• Set fees under Fee Settings if status is No fee',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 24,
                            ),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFECFDF5),
                              ),
                              border: TableBorder.all(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              columns: const [
                                DataColumn(label: Text('#')),
                                DataColumn(label: Text('Student')),
                                DataColumn(label: Text('Admission No')),
                                DataColumn(label: Text('Class')),
                                DataColumn(label: Text('Fee')),
                                DataColumn(label: Text('Paid')),
                                DataColumn(label: Text('Balance')),
                                DataColumn(label: Text('Status')),
                              ],
                              rows: [
                                for (int i = 0; i < list.length; i++)
                                  DataRow(
                                    cells: [
                                      DataCell(Text('${i + 1}')),
                                      DataCell(
                                        Text(
                                          list[i].student.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(list[i].student.admissionNo),
                                      ),
                                      DataCell(Text(list[i].className)),
                                      DataCell(Text(money(list[i].totalFee))),
                                      DataCell(
                                        Text(
                                          money(list[i].paid),
                                          style: const TextStyle(
                                            color: Color(0xFF059669),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          money(list[i].balance),
                                          style: TextStyle(
                                            color: list[i].balance > 0.01
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFF059669),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(list[i].status)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            list[i].status,
                                            style: TextStyle(
                                              color:
                                                  _statusColor(list[i].status),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
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
                      ),
          ),
        ],
      ),
    );
  }

  Widget _dd({
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
          dropdownColor: const Color(0xFF064E3B),
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
}

class _StatusRow {
  final Student student;
  final String className;
  final double totalFee;
  final double paid;
  final double balance;
  final String status;

  _StatusRow({
    required this.student,
    required this.className,
    required this.totalFee,
    required this.paid,
    required this.balance,
    required this.status,
  });
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../models/attendance.dart';
import '../../models/result.dart';
import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../models/student_fee_payment.dart';
import '../../models/timetable.dart';
import '../../services/attendance_storage.dart';
import '../../services/auth_service.dart';
import '../../services/school_fee_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/student_storage.dart';
import '../../services/result_storage.dart';
import '../../services/timetable_storage.dart';

class ParentPortalScreen extends StatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  bool loading = true;
  List<_ChildBundle> children = [];
  String selectedSession = Sessions.current();
  String selectedTerm = 'First Term';
  final sessions = Sessions.list();
  final terms = Sessions.terms;

  @override
  void initState() {
    super.initState();
    loadChildren();
  }

  String _normAdmission(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  /// Flexible match: exact, ignore spaces, strip leading zeros in last segment.
  Student? findStudent(String linkedNo, List<Student> all) {
    final target = _normAdmission(linkedNo);
    for (final s in all) {
      final a = _normAdmission(s.admissionNo);
      if (a == target) return s;
    }
    // Compare numeric tail only (HSC/2026/0001 vs HSC/2026/1)
    String tail(String v) {
      final parts = v.split(RegExp(r'[/\\-]'));
      final last = parts.isEmpty ? v : parts.last;
      return last.replaceFirst(RegExp(r'^0+'), '');
    }

    final tTail = tail(target);
    for (final s in all) {
      if (tail(_normAdmission(s.admissionNo)) == tTail && tTail.isNotEmpty) {
        return s;
      }
    }
    return null;
  }

  Future<void> loadChildren() async {
    setState(() => loading = true);

    final user = AuthService.currentUser;
    List<String> linked = [];
    if (user != null) {
      linked = List<String>.from(user.childrenAdmissionNos);
      if (linked.isEmpty) {
        final raw = user.linkedAdmissionNos;
        if (raw != null && raw.trim().isNotEmpty) {
          linked = raw
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }

    final allStudents = await StudentStorage.getStudents();
    final allAssignments = await StudentClassStorage.getStudents();
    final bundles = <_ChildBundle>[];

    // Always use the filters the parent selected (accurate session/term)
    final session = selectedSession.trim();
    final term = selectedTerm.trim();

    for (final no in linked) {
      final student = findStudent(no, allStudents);
      if (student == null) continue;

      final adm = student.admissionNo.trim().toLowerCase();

      // Class for the SELECTED session only (promoted/repeated aware)
      final forSession = allAssignments
          .where((a) =>
              a.admissionNo.trim().toLowerCase() == adm &&
              a.session.trim() == session)
          .toList();
      final sc = forSession.isNotEmpty ? forSession.last : null;
      final className = sc?.className ?? '';

      // Fees for selected session/term only
      double totalFee = 0;
      double paid = 0;
      double balance = 0;
      bool feeConfigured = false;

      if (className.isNotEmpty &&
          className.trim().toLowerCase() != 'graduated') {
        final fee = await SchoolFeeStorage.getFee(className, session, term);
        if (fee != null) {
          feeConfigured = true;
          totalFee = fee.totalFee;
          paid = await StudentFeePaymentStorage.totalPaidForTerm(
            student.admissionNo,
            session: session,
            term: term,
          );
          balance = totalFee - paid;
        }
      }

      // Results — selected session + term only
      final allResults = await ResultStorage.getStudentResults(student.admissionNo);
      final results = allResults
          .where((r) =>
              r.session.trim().toLowerCase() == session.toLowerCase() &&
              r.term.trim().toLowerCase() == term.toLowerCase())
          .toList();

      // Attendance — selected session + term only
      final allAtt = await AttendanceStorage.getAttendance();
      final attendance = allAtt
          .where((a) =>
              a.admissionNo.trim().toLowerCase() == adm &&
              a.session.trim().toLowerCase() == session.toLowerCase() &&
              a.term.trim().toLowerCase() == term.toLowerCase())
          .toList();

      int present = 0, absent = 0, late = 0;
      for (final a in attendance) {
        final st = a.status.trim().toLowerCase();
        if (st == 'present') {
          present++;
        } else if (st == 'absent') {
          absent++;
        } else if (st == 'late') {
          late++;
        }
      }

      // Timetable for the class in selected session
      List<Timetable> timetable = [];
      if (className.isNotEmpty &&
          className.trim().toLowerCase() != 'graduated') {
        final allTt = await TimetableStorage.getTimetables();
        String norm(String v) =>
            v.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
        final cn = norm(className);
        timetable = allTt.where((tt) {
          final tc = norm(tt.className);
          final classOk = tc == cn || tc.startsWith(cn) || cn.startsWith(tc);
          final sess = tt.session.trim();
          final sessionOk =
              sess.isEmpty || sess.toLowerCase() == session.toLowerCase();
          return classOk && sessionOk;
        }).toList();
      }

      // Payments for selected session/term only
      final allPay = await StudentFeePaymentStorage.getPayments();
      final payments = allPay
          .where((p) =>
              p.admissionNo.trim().toLowerCase() == adm &&
              p.session.trim().toLowerCase() == session.toLowerCase() &&
              p.term.trim().toLowerCase() == term.toLowerCase())
          .toList();

      bundles.add(
        _ChildBundle(
          student: student,
          studentClass: sc,
          session: session,
          term: term,
          totalFee: totalFee,
          totalPaid: paid,
          balance: balance,
          feeConfigured: feeConfigured,
          results: results,
          attendance: attendance,
          present: present,
          absent: absent,
          late: late,
          timetable: timetable,
          payments: payments,
        ),
      );
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parent Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View results, attendance, timetable and fees for your children',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _filterDropdown(
                        value: sessions.contains(selectedSession)
                            ? selectedSession
                            : sessions.first,
                        items: sessions,
                        onChanged: (v) async {
                          if (v == null) return;
                          selectedSession = v;
                          await loadChildren();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _filterDropdown(
                        value: selectedTerm,
                        items: terms,
                        onChanged: (v) async {
                          if (v == null) return;
                          selectedTerm = v;
                          await loadChildren();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : children.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            (AuthService.currentUser?.childrenAdmissionNos
                                        .isEmpty ??
                                    true)
                                ? 'No children linked to this account.\n'
                                    'Ask the school to link admission numbers on your user profile.\n'
                                    'Example: HSC/2026/0001, HSC/2026/0002'
                                : 'Linked numbers were not found in student records.\n'
                                    'Linked: ${AuthService.currentUser?.linkedAdmissionNos ?? ""}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadChildren,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          itemCount: children.length,
                          itemBuilder: (context, index) {
                            return _childCard(children[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E3A8A),
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

  Widget _childCard(_ChildBundle c) {
    final owing = c.feeConfigured && c.balance > 0.01;
    final classLabel = c.studentClass?.className ?? 'Not assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: children.length == 1,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            c.student.firstName.isNotEmpty
                ? c.student.firstName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          c.student.fullName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${c.student.admissionNo} · $classLabel',
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
        children: [
          // Class / session info
          _sectionLabel('Class placement'),
          _infoRow('Class', classLabel),
          _infoRow('Session', c.session),
          _infoRow('Viewing term', selectedTerm),
          const SizedBox(height: 10),

          // Fees
          _sectionLabel('School fees'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: owing
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: owing
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFA7F3D0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !c.feeConfigured
                      ? 'Fee not set for this class/term'
                      : owing
                          ? 'Still owing'
                          : 'Fees up to date',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: !c.feeConfigured
                        ? const Color(0xFF6B7280)
                        : owing
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF047857),
                  ),
                ),
                if (c.feeConfigured) ...[
                  const SizedBox(height: 6),
                  Text('Total fee: ₦${c.totalFee.toStringAsFixed(0)}'),
                  Text('Paid: ₦${c.totalPaid.toStringAsFixed(0)}'),
                  Text(
                    'Balance: ₦${c.balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: owing
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Attendance
          _sectionLabel('Attendance ($selectedTerm)'),
          Row(
            children: [
              _statChip('Present', '${c.present}', const Color(0xFF059669)),
              const SizedBox(width: 8),
              _statChip('Absent', '${c.absent}', const Color(0xFFDC2626)),
              const SizedBox(width: 8),
              _statChip('Late', '${c.late}', const Color(0xFFD97706)),
            ],
          ),
          if (c.attendance.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No attendance records for this term yet.',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12.5,
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Results
          _sectionLabel('Results ($selectedTerm)'),
          if (c.results.isEmpty)
            Text(
              'No results entered for this term yet.',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12.5,
              ),
            )
          else
            ...c.results.map(
              (r) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  r.subjectName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'CA1 ${r.ca1.toStringAsFixed(0)} · CA2 ${r.ca2.toStringAsFixed(0)} · Exam ${r.exam.toStringAsFixed(0)}',
                ),
                trailing: Text(
                  r.total.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Timetable (view only)
          _sectionLabel('Class timetable'),
          if (c.timetable.isEmpty)
            Text(
              'No timetable published for $classLabel yet.',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12.5,
              ),
            )
          else
            ...c.timetable.map(
              (t) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule, size: 18),
                title: Text(
                  '${t.day} · Period ${t.period}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${t.subject} · ${t.teacher}'),
                trailing: Text(
                  t.room.isEmpty ? '' : t.room,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildBundle {
  final Student student;
  final StudentClass? studentClass;
  final String session;
  final String term;
  final double totalFee;
  final double totalPaid;
  final double balance;
  final bool feeConfigured;
  final List<Result> results;
  final List<Attendance> attendance;
  final int present;
  final int absent;
  final int late;
  final List<Timetable> timetable;
  final List<StudentFeePayment> payments;

  _ChildBundle({
    required this.student,
    required this.studentClass,
    required this.session,
    required this.term,
    required this.totalFee,
    required this.totalPaid,
    required this.balance,
    required this.feeConfigured,
    required this.results,
    required this.attendance,
    required this.present,
    required this.absent,
    required this.late,
    required this.timetable,
    required this.payments,
  });
}

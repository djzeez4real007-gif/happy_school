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
import '../../services/result_storage.dart';
import '../../services/school_fee_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/timetable_storage.dart';

/// Premium single-child parent view.
class ParentChildDetailScreen extends StatefulWidget {
  final Student student;

  const ParentChildDetailScreen({super.key, required this.student});

  @override
  State<ParentChildDetailScreen> createState() =>
      _ParentChildDetailScreenState();
}

class _ParentChildDetailScreenState extends State<ParentChildDetailScreen> {
  bool loading = true;
  String selectedSession = Sessions.current();
  String selectedTerm = 'First Term';
  final sessions = Sessions.list();
  final terms = Sessions.terms;

  StudentClass? studentClass;
  double totalFee = 0;
  double paid = 0;
  double discount = 0;
  double balance = 0;
  bool feeConfigured = false;
  List<Result> results = [];
  List<Attendance> attendance = [];
  int present = 0, absent = 0, late = 0;
  List<Timetable> timetable = [];
  List<StudentFeePayment> payments = [];

  @override
  void initState() {
    super.initState();
    _preferLatestSession().then((_) => load());
  }

  Future<void> _preferLatestSession() async {
    final all = await StudentClassStorage.getStudents();
    final adm = widget.student.admissionNo.trim().toLowerCase();
    final mine =
        all.where((a) => a.admissionNo.trim().toLowerCase() == adm).toList();
    if (mine.isEmpty) return;
    mine.sort((a, b) => b.session.compareTo(a.session));
    selectedSession = mine.first.session;
  }

  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

  Future<void> load() async {
    setState(() => loading = true);
    final student = widget.student;
    final session = selectedSession.trim();
    final term = selectedTerm.trim();
    final adm = student.admissionNo.trim().toLowerCase();

    final allAssignments = await StudentClassStorage.getStudents();
    final forSession = allAssignments
        .where((a) =>
            a.admissionNo.trim().toLowerCase() == adm &&
            a.session.trim() == session)
        .toList();
    studentClass = forSession.isNotEmpty ? forSession.last : null;
    final className = studentClass?.className ?? '';

    totalFee = 0;
    paid = 0;
    discount = 0;
    balance = 0;
    feeConfigured = false;
    if (className.isNotEmpty &&
        className.toLowerCase() != 'graduated' &&
        className.toLowerCase() != 'left') {
      final fee = await SchoolFeeStorage.getFee(className, session, term);
      if (fee != null) {
        feeConfigured = true;
        totalFee = fee.totalFee;
        paid = await StudentFeePaymentStorage.totalPaidForTerm(
          student.admissionNo,
          session: session,
          term: term,
        );
        discount = await StudentFeePaymentStorage.totalDiscountForTerm(
          student.admissionNo,
          session: session,
          term: term,
        );
        balance = totalFee - paid - discount;
      }
    }

    final allResults = await ResultStorage.getStudentResults(student.admissionNo);
    results = allResults
        .where((r) =>
            r.session.trim().toLowerCase() == session.toLowerCase() &&
            r.term.trim().toLowerCase() == term.toLowerCase())
        .toList()
      ..sort((a, b) => a.subjectName.compareTo(b.subjectName));

    final allAtt = await AttendanceStorage.getAttendance();
    attendance = allAtt
        .where((a) =>
            a.admissionNo.trim().toLowerCase() == adm &&
            a.session.trim().toLowerCase() == session.toLowerCase() &&
            a.term.trim().toLowerCase() == term.toLowerCase())
        .toList();
    present = absent = late = 0;
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

    timetable = [];
    if (className.isNotEmpty) {
      final allTt = await TimetableStorage.getTimetables();
      final cn = _norm(className);
      timetable = allTt.where((tt) {
        final tc = _norm(tt.className);
        final classOk = tc == cn || tc.startsWith(cn) || cn.startsWith(tc);
        final sess = tt.session.trim();
        final sessionOk =
            sess.isEmpty || sess.toLowerCase() == session.toLowerCase();
        return classOk && sessionOk;
      }).toList();
    }

    final allPay = await StudentFeePaymentStorage.getPayments();
    payments = allPay
        .where((p) =>
            p.admissionNo.trim().toLowerCase() == adm &&
            p.session.trim().toLowerCase() == session.toLowerCase() &&
            p.term.trim().toLowerCase() == term.toLowerCase())
        .toList();

    if (!mounted) return;
    setState(() => loading = false);
  }

  String money(double v) {
    final s = v.toStringAsFixed(0);
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₦$withCommas';
  }

  double get resultAverage {
    if (results.isEmpty) return 0;
    final sum = results.fold<double>(0, (a, r) => a + r.total);
    return sum / results.length;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final classLabel = studentClass?.className ?? 'Not assigned';
    final initial = s.firstName.isNotEmpty
        ? s.firstName[0].toUpperCase()
        : (s.surname.isNotEmpty ? s.surname[0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          // ===== Premium header =====
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              left: 8,
              right: 12,
              bottom: 18,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E3A8A),
                  AppColors.primary,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Student Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: load,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF60A5FA), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.admissionNo,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              _headerPill(classLabel, Icons.class_rounded),
                              _headerPill(
                                  selectedTerm.replaceAll(' Term', ''),
                                  Icons.calendar_today_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _headerDropdown(
                        sessions.contains(selectedSession)
                            ? selectedSession
                            : sessions.first,
                        sessions,
                        (v) async {
                          if (v == null) return;
                          selectedSession = v;
                          await load();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _headerDropdown(
                        selectedTerm,
                        terms,
                        (v) async {
                          if (v == null) return;
                          selectedTerm = v;
                          await load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== Body =====
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                    children: [
                      // Fee status banner
                      _feeBanner(),
                      const SizedBox(height: 16),

                      // Quick stats
                      Row(
                        children: [
                          _miniStat(
                            'Average',
                            results.isEmpty
                                ? '—'
                                : resultAverage.toStringAsFixed(1),
                            AppColors.primary,
                            Icons.insights_rounded,
                          ),
                          const SizedBox(width: 10),
                          _miniStat(
                            'Subjects',
                            '${results.length}',
                            const Color(0xFF7C3AED),
                            Icons.menu_book_rounded,
                          ),
                          const SizedBox(width: 10),
                          _miniStat(
                            'Present',
                            '$present',
                            const Color(0xFF059669),
                            Icons.check_circle_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      _sectionHeader('Results', Icons.grade_rounded),
                      if (results.isEmpty)
                        _emptyCard('No results for this session & term')
                      else
                        ...results.map((r) => _resultTile(r)),

                      const SizedBox(height: 18),
                      _sectionHeader('Attendance', Icons.fact_check_rounded),
                      _attendanceCard(),

                      const SizedBox(height: 18),
                      _sectionHeader('Timetable', Icons.schedule_rounded),
                      if (timetable.isEmpty)
                        _emptyCard('No timetable for this class')
                      else
                        ...timetable.map((tt) => _timetableTile(tt)),

                      if (payments.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _sectionHeader(
                            'Payments this term', Icons.receipt_long_rounded),
                        ...payments.map((p) => _paymentTile(p)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _feeBanner() {
    final owing = feeConfigured && balance > 0.01;
    final paidUp = feeConfigured && balance <= 0.01;
    final colors = !feeConfigured
        ? [const Color(0xFF64748B), const Color(0xFF94A3B8)]
        : owing
            ? [const Color(0xFF991B1B), const Color(0xFFDC2626)]
            : [const Color(0xFF065F46), const Color(0xFF059669)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                !feeConfigured
                    ? Icons.info_outline_rounded
                    : owing
                        ? Icons.warning_amber_rounded
                        : Icons.verified_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                !feeConfigured
                    ? 'Fee not configured'
                    : owing
                        ? 'Outstanding balance'
                        : 'Fees fully paid',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (feeConfigured) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _feeCol('Total', money(totalFee))),
                Expanded(child: _feeCol('Paid', money(paid))),
                Expanded(child: _feeCol('Discount', money(discount))),
                Expanded(child: _feeCol('Balance', money(balance))),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'School has not set fees for this class / session / term yet.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _feeCol(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      );

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder(context)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Text(
          msg,
          style: TextStyle(color: AppColors.textSecondary(context)),
        ),
      );

  Widget _resultTile(Result r) {
    final color = r.total >= 50
        ? const Color(0xFF059669)
        : r.total >= 40
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              r.subjectName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              r.total.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          _attChip('Present', present, const Color(0xFF059669)),
          const SizedBox(width: 8),
          _attChip('Absent', absent, const Color(0xFFDC2626)),
          const SizedBox(width: 8),
          _attChip('Late', late, const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _attChip(String label, int value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _timetableTile(Timetable tt) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tt.day.substring(0, 3),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tt.subject,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${tt.period} · ${tt.teacher}',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _paymentTile(StudentFeePayment p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_rounded, color: Color(0xFF059669)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p.receiptNo,
                style: const TextStyle(fontWeight: FontWeight.w700),
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
      );

  Widget _headerPill(String text, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );

  Widget _headerDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0F172A),
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

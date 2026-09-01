import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../services/attendance_storage.dart';
import '../../services/auth_service.dart';
import '../../services/class_storage.dart';
import '../../services/staff_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_fee_payment_storage.dart';
import '../../services/school_fee_storage.dart';
import '../../services/student_storage.dart';
import '../../services/teacher_storage.dart';
import '../../services/user_storage.dart';
import '../../services/announcement_storage.dart';
import '../../models/announcement.dart';
import '../teachers/my_teaching_screen.dart';
import '../student_portal/student_portal_home_screen.dart';
import 'accountant_dashboard_screen.dart';
import 'class_teacher_dashboard_screen.dart';
import 'parent_home_dashboard.dart';


/// Routes each role to the right home screen.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole;
    switch (role) {
      case 'subject_teacher':
        // Should rarely open; sidebar lands on My Teaching.
        return const _RoleRedirectMyTeaching();
      case 'accountant':
        return const AccountantDashboardScreen();
      case 'class_teacher':
        return const ClassTeacherDashboardScreen();
      case 'parent':
        return const ParentHomeDashboard();
      case 'student':
        return const StudentPortalHomeScreen();
      default:
        // admin, principal, others
        return const AdminDashboardScreen();
    }
  }
}

class _RoleRedirectMyTeaching extends StatelessWidget {
  const _RoleRedirectMyTeaching();
  @override
  Widget build(BuildContext context) => const MyTeachingScreen();
}

/// Premium school-wide dashboard — admin / principal (view only).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool loading = true;

  late String selectedSession;
  final List<String> sessions = Sessions.list();

  late final String todayLabel;
  late final String todayKey;

  int totalStudents = 0;
  int sessionStudents = 0;
  int totalTeachers = 0;
  int partTimeTeachers = 0;
  int fullTimeTeachers = 0;
  int parentCount = 0;
  int totalOtherStaff = 0;
  int totalClasses = 0;

  int presentToday = 0;
  int absentToday = 0;
  int attendanceMarked = 0;

  double feesCollectedSession = 0;
  double feesCashSession = 0;
  double feesPosSession = 0;
  double feesTransferSession = 0;
  double feesCashToday = 0;
  double feesPosToday = 0;
  double feesTransferToday = 0;
  double feesExpectedSession = 0;
  double feesOutstandingSession = 0;
  double feesCollectedToday = 0;
  int receiptsToday = 0;
  int receiptsSession = 0;

  List<Announcement> announcements = [];

  late final AnimationController _lineController;

  @override
  void initState() {
    super.initState();
    selectedSession = Sessions.current();
    if (!sessions.contains(selectedSession)) {
      selectedSession = sessions.isNotEmpty ? sessions.first : '2026/2027';
    }
    // Prefer 2026/2027 if that is the working school year and current() lags
    // (calendar still before September).
    final preferred = '2026/2027';
    if (sessions.contains(preferred) &&
        selectedSession != preferred &&
        DateTime.now().month < 9 &&
        DateTime.now().year == 2026) {
      selectedSession = preferred;
    }

    final now = DateTime.now();
    todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    todayLabel = DateFormat('EEEE, d MMM yyyy').format(now);

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _load();
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  bool _dateMatchesToday(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return false;
    if (s.startsWith(todayKey)) return true;
    try {
      final d = DateTime.parse(s);
      final n = DateTime.now();
      return d.year == n.year && d.month == n.month && d.day == n.day;
    } catch (_) {
      final parts = s.split(RegExp(r'[/\-.]'));
      if (parts.length >= 3) {
        try {
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final c = int.parse(parts[2]);
          final n = DateTime.now();
          if (c > 31) {
            return a == n.day && b == n.month && c == n.year;
          }
          if (a > 31) {
            return c == n.day && b == n.month && a == n.year;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final students = await StudentStorage.getStudents();
      final teachers = await TeacherStorage.getTeachers();
      int parents = 0;
      try {
        final users = await UserStorage.getUsers();
        parents = users
            .where((u) =>
                u.role.trim().toLowerCase() == 'parent' && u.isActive)
            .length;
      } catch (_) {}
      try {
        await StaffStorage.open();
      } catch (_) {}
      List otherStaff = [];
      try {
        otherStaff = StaffStorage.getAll(activeOnly: true);
      } catch (_) {}
      final classes = await ClassStorage.getClasses();
      final assignments = await StudentClassStorage.getStudents();
      final payments = await StudentFeePaymentStorage.getPayments();
      final attendance = await AttendanceStorage.getAttendance();

      final sessionNorm = selectedSession.trim().toLowerCase();
      final sessAssign = assignments.where((a) {
        final sn = a.session.trim().toLowerCase();
        final cn = a.className.trim().toLowerCase();
        if (sn != sessionNorm) return false;
        if (cn == 'left' || cn == 'graduated' || cn == 'withdrawn') {
          return false;
        }
        return a.admissionNo.trim().isNotEmpty;
      }).toList();
      final uniqueAdm =
          sessAssign.map((a) => a.admissionNo.trim().toLowerCase()).toSet();

      double collectedSession = 0;
      double collectedToday = 0;
      double cashSession = 0, posSession = 0, transferSession = 0;
      double cashToday = 0, posToday = 0, transferToday = 0;
      int rToday = 0;
      int rSession = 0;

      void addMethod(String method, double amt, {required bool session, required bool today}) {
        final m = method.trim().toLowerCase();
        final hasCash = m.contains('cash');
        final hasPos = m.contains('pos') || m.contains('card');
        final hasTransfer =
            m.contains('transfer') || m.contains('bank') || m.contains('tfr');
        final n = [hasCash, hasPos, hasTransfer].where((x) => x).length;
        void apply(double v, void Function(double) toCash, void Function(double) toPos, void Function(double) toTfr, void Function(double) toOther) {
          if (n >= 2) {
            final share = v / n;
            if (hasCash) toCash(share);
            if (hasPos) toPos(share);
            if (hasTransfer) toTfr(share);
          } else if (hasPos) {
            toPos(v);
          } else if (hasTransfer) {
            toTfr(v);
          } else if (hasCash) {
            toCash(v);
          }
        }
        if (session) {
          apply(
            amt,
            (v) => cashSession += v,
            (v) => posSession += v,
            (v) => transferSession += v,
            (_) {},
          );
        }
        if (today) {
          apply(
            amt,
            (v) => cashToday += v,
            (v) => posToday += v,
            (v) => transferToday += v,
            (_) {},
          );
        }
      }

      for (final p in payments) {
        final paySession = p.session.trim().toLowerCase();
        final inSession = paySession == sessionNorm;
        final inToday = _dateMatchesToday(p.paymentDate) &&
            (paySession == sessionNorm || paySession.isEmpty);
        if (inSession) {
          collectedSession += p.amountPaid;
          rSession++;
        }
        if (inToday) {
          collectedToday += p.amountPaid;
          rToday++;
        }
        if (inSession || inToday) {
          addMethod(p.paymentMethod, p.amountPaid, session: inSession, today: inToday);
        }
      }

      // Expected & outstanding for selected session (all terms)
      double expectedSession = 0;
      double outstandingSession = 0;
      const terms = ['First Term', 'Second Term', 'Third Term'];
      // admissionNo (original case) -> className
      final byAdm = <String, String>{};
      for (final a in sessAssign) {
        final adm = a.admissionNo.trim();
        if (adm.isNotEmpty) byAdm[adm] = a.className.trim();
      }
      for (final entry in byAdm.entries) {
        final adm = entry.key;
        final cls = entry.value;
        for (final term in terms) {
          try {
            final fee = await SchoolFeeStorage.getFee(
              cls,
              selectedSession,
              term,
            );
            if (fee == null) continue;
            final feeTotal = fee.totalFee;
            expectedSession += feeTotal;
            final paid = await StudentFeePaymentStorage.totalPaidForTerm(
              adm,
              session: selectedSession,
              term: term,
            );
            final discount =
                await StudentFeePaymentStorage.totalDiscountForTerm(
              adm,
              session: selectedSession,
              term: term,
            );
            final bal = feeTotal - paid - discount;
            if (bal > 0.01) outstandingSession += bal;
          } catch (_) {}
        }
      }

      int present = 0;
      int absent = 0;
      final seen = <String>{};
      for (final a in attendance) {
        if (!_dateMatchesToday(a.date)) continue;
        final aSess = a.session.trim().toLowerCase();
        if (aSess.isNotEmpty && aSess != sessionNorm) continue;
        final key = a.admissionNo.trim().toLowerCase();
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);
        final st = a.status.trim().toLowerCase();
        if (st.contains('present') || st == 'p') {
          present++;
        } else if (st.contains('absent') || st == 'a') {
          absent++;
        }
      }


      List<Announcement> anns = [];
      try {
        anns = await AnnouncementStorage.getAnnouncements();
        // Pinned first, then by date desc if possible
        anns.sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.date.compareTo(a.date);
        });
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        totalStudents = students.length;
        sessionStudents = uniqueAdm.length;
        partTimeTeachers = teachers.where((x) {
          final et = x.employmentType.trim().toLowerCase();
          return et.contains('part');
        }).length;
        fullTimeTeachers = teachers.where((x) {
          final et = x.employmentType.trim().toLowerCase();
          return !et.contains('part');
        }).length;
        totalTeachers = fullTimeTeachers + partTimeTeachers;
        parentCount = parents;
        totalOtherStaff = otherStaff.length;
        totalClasses = classes.length;
        presentToday = present;
        absentToday = absent;
        attendanceMarked = seen.length;
        feesCollectedSession = collectedSession;
        feesCashSession = cashSession;
        feesPosSession = posSession;
        feesTransferSession = transferSession;
        feesExpectedSession = expectedSession;
        feesOutstandingSession = outstandingSession;
        feesCollectedToday = collectedToday;
        feesCashToday = cashToday;
        feesPosToday = posToday;
        feesTransferToday = transferToday;
        receiptsToday = rToday;
        receiptsSession = rSession;
        announcements = anns;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  String _money(double v) {
    final s = v.toStringAsFixed(0);
    final withCommas = s.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₦$withCommas';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = user?.fullName ?? 'User';
    final role = user?.role ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _hero(name, role)),
                  if (announcements.isNotEmpty)
                    SliverToBoxAdapter(child: _announcementBanner()),
                  SliverToBoxAdapter(child: _animatedLine()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                      ),
                      delegate: SliverChildListDelegate([
                        _miniStat(
                          'Students',
                          '$totalStudents',
                          'Registry',
                          Icons.school_rounded,
                          const Color(0xFF2563EB),
                        ),
                        _miniStat(
                          'This session',
                          '$sessionStudents',
                          selectedSession,
                          Icons.groups_rounded,
                          const Color(0xFF7C3AED),
                        ),
                        _miniStat(
                          'Full-time',
                          '$fullTimeTeachers',
                          'Teachers',
                          Icons.person_rounded,
                          const Color(0xFF059669),
                        ),
                        _miniStat(
                          'Part-time',
                          '$partTimeTeachers',
                          'Teachers',
                          Icons.schedule_rounded,
                          const Color(0xFFEA580C),
                        ),
                        _miniStat(
                          'Parents',
                          '$parentCount',
                          'Portal accounts',
                          Icons.family_restroom_rounded,
                          const Color(0xFF7C3AED),
                        ),
                        _miniStat(
                          'Other staff',
                          '$totalOtherStaff',
                          'Non-teaching',
                          Icons.badge_rounded,
                          const Color(0xFFD97706),
                        ),
                        _miniStat(
                          'Classes',
                          '$totalClasses',
                          'Arms open',
                          Icons.class_rounded,
                          const Color(0xFF0EA5E9),
                        ),
                        _miniStat(
                          'Present today',
                          '$presentToday',
                          attendanceMarked == 0
                              ? 'No mark yet'
                              : '$absentToday absent',
                          Icons.fact_check_rounded,
                          const Color(0xFF10B981),
                        ),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(child: _animatedLine(pad: true)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _financeCard(isDark),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: _attendanceStrip(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _animatedLine(pad: true)),
                  SliverToBoxAdapter(child: _footer()),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
      ),
    );
  }

  Widget _animatedLine({bool pad = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, pad ? 8 : 0, 16, pad ? 4 : 0),
      child: AnimatedBuilder(
        animation: _lineController,
        builder: (context, _) {
          return Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2 * _lineController.value, 0),
                end: Alignment(1.0 + 2 * _lineController.value, 0),
                colors: const [
                  Color(0x003B82F6),
                  Color(0xFF3B82F6),
                  Color(0xFF60A5FA),
                  Color(0xFF3B82F6),
                  Color(0x003B82F6),
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hero(String name, String role) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1D4ED8),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()} ✨',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  todayLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Session selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Session',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sessions.contains(selectedSession)
                          ? selectedSession
                          : sessions.first,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E3A8A),
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      items: sessions
                          .where((s) {
                            // Keep list usable: show from 2020 onward but
                            // prioritize nearby years in UI via full list
                            return true;
                          })
                          .take(40)
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selectedSession = v);
                        _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: AppColors.textPrimary(context),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.textPrimary(context),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: Color(0xFF059669), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial overview',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      'Session $selectedSession',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary(context),
                      ),
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
                child: _financePill(
                  'Expected',
                  _money(feesExpectedSession),
                  'All terms · $selectedSession',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _financePill(
                  'Collected (session)',
                  _money(feesCollectedSession),
                  '$receiptsSession receipt(s)',
                  breakdown:
                      'Cash ${_money(feesCashSession)} · POS ${_money(feesPosSession)} · Transfer ${_money(feesTransferSession)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _financePill(
                  'Outstanding',
                  _money(feesOutstandingSession),
                  'Still due',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _financePill(
                  'Collected today',
                  _money(feesCollectedToday),
                  '$receiptsToday receipt(s)',
                  breakdown:
                      'Cash ${_money(feesCashToday)} · POS ${_money(feesPosToday)} · Transfer ${_money(feesTransferToday)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financePill(String label, String value, String sub, {String? breakdown}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF047857),
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted(context),
            ),
          ),
          if (breakdown != null && breakdown.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              breakdown,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _attendanceStrip() {
    final rate = attendanceMarked == 0
        ? 0.0
        : (presentToday / attendanceMarked).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded,
                  color: Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 8),
              Text(
                'Attendance · today',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              Text(
                attendanceMarked == 0
                    ? 'Not marked'
                    : '${(rate * 100).toStringAsFixed(0)}% present',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: attendanceMarked == 0 ? 0 : rate,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$presentToday present · $absentToday absent · $attendanceMarked marked',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }


  Widget _announcementBanner() {
    final text = announcements.map((a) {
      final title = a.title.trim();
      final msg = a.message.trim();
      if (title.isNotEmpty && msg.isNotEmpty) return '📢 $title — $msg';
      if (title.isNotEmpty) return '📢 $title';
      return '📢 $msg';
    }).join('     •     ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'NEWS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRect(
                child: _MarqueeText(
                  text: text.isEmpty ? 'No announcements' : text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    final year = DateTime.now().year;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Text(
            '© $year Happy School. All Rights Reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted(context),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}


/// Continuous left-to-right looping marquee.
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _textWidth = 0;
  double _viewport = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
    }
  }

  void _measureAndStart() {
    if (!mounted) return;
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    _textWidth = tp.width + 48; // gap between loops

    // Speed ~40 px/sec
    final seconds = (_textWidth / 40).clamp(6.0, 60.0);
    _ctrl
      ..duration = Duration(milliseconds: (seconds * 1000).round())
      ..repeat();
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.maxWidth;
        return ClipRect(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final w = _textWidth <= 0 ? _viewport + 200 : _textWidth;
              final dx = -_ctrl.value * w;
              return Stack(
                children: [
                  Transform.translate(
                    offset: Offset(dx, 0),
                    child: _line(),
                  ),
                  Transform.translate(
                    offset: Offset(dx + w, 0),
                    child: _line(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _line() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}

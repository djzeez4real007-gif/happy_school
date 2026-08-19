import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../models/announcement.dart';

import '../../services/announcement_storage.dart';
import '../../services/student_storage.dart';
import '../../services/teacher_storage.dart';
import '../../services/subject_storage.dart';
import '../../services/class_storage.dart';

import '../announcements/announcement_list_screen.dart';
import '../fees/fees_dashboard_screen.dart';
import '../subjects/subject_list_screen.dart';
import '../teachers/teacher_list_screen.dart';
import '../classes/class_list_screen.dart';
import '../classes/class_subject_dashboard_screen.dart';
import '../students/student_menu_screen.dart';
import '../results/result_entry_screen.dart';
import '../results/broadsheet_screen.dart';
import '../report_card/generate_report_card_screen.dart';
import '../fees/financial_reports_screen.dart';
import '../attendance/attendance_screen.dart';
import '../timetable/timetable_screen.dart';
import '../timetable/timetable_settings_screen.dart';
import '../promotion/student_promotion_screen.dart';
import '../parent/parent_portal_screen.dart';
import '../parent/parent_child_detail_screen.dart';

import '../../widgets/dashboard_header.dart';
import '../../widgets/stat_card.dart';
import '../../services/auth_service.dart';
import '../../services/student_class_storage.dart';
import '../../core/permissions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // DASHBOARD COUNTS
  // ============================================================

  int studentCount = 0;
  int teacherCount = 0;
  int subjectCount = 0;
  int classCount = 0;

  // ============================================================
  // ANNOUNCEMENTS
  // ============================================================

  List<Announcement> announcements = [];

  // ============================================================
  // ANNOUNCEMENT SLIDER
  // ============================================================

  late AnimationController _announcementController;

  final GlobalKey _announcementRowKey = GlobalKey();

  double _announcementRowWidth = 0;

  // Speed in pixels per second.
  // Increase this number to make the announcement faster.
  static const double _announcementSpeed = 40;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // CREATE ANNOUNCEMENT ANIMATION
    // ==========================================================

    _announcementController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _announcementController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _announcementController.repeat();
      }
    });

    loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> loadDashboard() async {
    final students = await StudentStorage.getStudents();
    final teachers = await TeacherStorage.getTeachers();
    final subjects = await SubjectStorage.getSubjects();
    final classes = await ClassStorage.getClasses();

    final latestAnnouncements = await AnnouncementStorage.getAnnouncements();

    latestAnnouncements.sort((a, b) {
      if (a.pinned == b.pinned) return 0;
      return a.pinned ? -1 : 1;
    });

    if (!mounted) return;

    setState(() {
      studentCount = students.length;
      teacherCount = teachers.length;
      subjectCount = subjects.length;
      classCount = classes.length;
      announcements = latestAnnouncements;
    });

    // Wait until the announcement row has been rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAnnouncementAnimation();
    });
  }

  // ============================================================
  // SETUP ANNOUNCEMENT ANIMATION
  // ============================================================

  void _setupAnnouncementAnimation() {
    if (!mounted) return;
    if (announcements.isEmpty) return;

    // Duration based on number of announcements (smooth continuous loop)
    final itemWidth = 292.0;
    final totalWidth = itemWidth * announcements.length;
    final seconds = (totalWidth / _announcementSpeed).clamp(10.0, 45.0);

    _announcementController.stop();
    _announcementController.duration = Duration(
      milliseconds: (seconds * 1000).round(),
    );
    _announcementController.repeat();
  }


  Future<List<Map<String, String>>> _loadParentChildren() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    var linked = List<String>.from(user.childrenAdmissionNos);
    if (linked.isEmpty &&
        (user.linkedAdmissionNos ?? '').trim().isNotEmpty) {
      linked = user.linkedAdmissionNos!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (linked.isEmpty) return [];

    final students = await StudentStorage.getStudents();
    final assignments = await StudentClassStorage.getStudents();
    final out = <Map<String, String>>[];

    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

    for (final no in linked) {
      final target = norm(no);
      final match =
          students.where((s) => norm(s.admissionNo) == target).toList();
      if (match.isEmpty) continue;
      final st = match.first;
      final asg = assignments
          .where((a) => norm(a.admissionNo) == norm(st.admissionNo))
          .toList();
      asg.sort((a, b) => b.session.compareTo(a.session));
      final latest = asg.isNotEmpty ? asg.first : null;
      out.add({
        'name': st.fullName,
        'admissionNo': st.admissionNo,
        'className': latest?.className ?? '',
        'session': latest?.session ?? '',
      });
    }
    return out;
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _parentChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning 👋";
    }

    if (hour < 17) {
      return "Good Afternoon ☀";
    }

    return "Good Evening 🌙";
  }

  // ============================================================
  // OPEN ANNOUNCEMENTS
  // ============================================================

  Future<void> openAnnouncements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnnouncementListScreen()),
    );

    if (!mounted) return;

    await loadDashboard();
  }

  // ============================================================
  // BUILD ONE ANNOUNCEMENT ITEM
  // ============================================================

  Widget buildAnnouncementItem(Announcement announcement) {
    return Container(
      width: 280,
      height: 52,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          Icon(
            announcement.pinned ? Icons.push_pin_rounded : Icons.campaign_rounded,
            size: 18,
            color: announcement.pinned ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    height: 1.1,
                  ),
                ),
                Text(
                  announcement.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAnnouncementTicker() {
    if (announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    // Auto-sliding horizontal ticker (left → right continuous)
    return Container(
      height: 64,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AnimatedBuilder(
          animation: _announcementController,
          builder: (context, child) {
            // Duplicate list so scroll loops seamlessly
            final items = [...announcements, ...announcements];
            final itemWidth = 292.0; // 280 + 12 margin
            final totalWidth = itemWidth * announcements.length;
            final dx = _announcementController.value * totalWidth;
            return OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-dx, 0),
                child: Row(
                  children: [
                    for (final a in items)
                      GestureDetector(
                        onTap: openAnnouncements,
                        child: buildAnnouncementItem(a),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole;
    final userName = AuthService.currentName.isNotEmpty
        ? AuthService.currentName
        : 'User';

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      // No AppBar / Drawer — AppShell provides sidebar navigation
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // DASHBOARD HEADER
              // ==================================================
              DashboardHeader(
                greeting: greeting(),
                name: userName,
                // Uncomment to show a picture ad under the blue greeting:
                // adImage: 'assets/images/ad_banner.png',
                // adCaption: 'Enrolment open — contact the office',
              ),


              // Parent: show linked children on main dashboard
              if (role == 'parent') ...[
                // Announcement above My Children (not below)
                buildAnnouncementTicker(),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<List<Map<String, String>>>(
                    future: _loadParentChildren(),
                    builder: (context, snap) {
                      final kids = snap.data ?? [];
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (kids.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.cardBorder(context),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.family_restroom_rounded,
                                size: 48,
                                color: Colors.blue.shade300,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No children linked yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ask the school admin to link your child\'s admission number to this parent account.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1D4ED8),
                                      Color(0xFF60A5FA),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My Children',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                      ),
                                    ),
                                    Text(
                                      'Tap a card to view full academic & fee details',
                                      style: TextStyle(
                                        color: AppColors.textSecondary(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${kids.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...kids.map((k) {
                            final name = k['name'] ?? '';
                            final initial =
                                name.isNotEmpty ? name[0].toUpperCase() : '?';
                            final className = k['className'] ?? '';
                            final session = k['session'] ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D4ED8)
                                        .withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    final students =
                                        await StudentStorage.getStudents();
                                    final adm = (k['admissionNo'] ?? '')
                                        .trim()
                                        .toLowerCase();
                                    final match = students
                                        .where((s) =>
                                            s.admissionNo
                                                .trim()
                                                .toLowerCase() ==
                                            adm)
                                        .toList();
                                    if (!context.mounted) return;
                                    if (match.isEmpty) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ParentChildDetailScreen(
                                          student: match.first,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.cardBorder(context),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF1E3A8A),
                                                Color(0xFF3B82F6),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                k['admissionNo'] ?? '',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary(
                                                          context),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: [
                                                  if (className.isNotEmpty)
                                                    _parentChip(
                                                      className,
                                                      const Color(0xFF1D4ED8),
                                                    ),
                                                  if (session.isNotEmpty)
                                                    _parentChip(
                                                      session,
                                                      const Color(0xFF059669),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],

if (role != 'parent') const SizedBox(height: 12),

              // ==================================================
              // MOVING ANNOUNCEMENTS
              // ==================================================
              if (role != 'parent') buildAnnouncementTicker(),

              // ==================================================
              // DASHBOARD CARDS (not for parent — they use My Children)
              // ==================================================
              if (role != 'parent')
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,

                  children: [
                    // ==================================================
                    // STUDENTS
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.students))
                    StatCard(
                      icon: Icons.people,
                      title: "Students",
                      value: studentCount.toString(),
                      color: Colors.blue,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentMenuScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboard();
                      },
                    ),

                    // ==================================================
                    // TEACHERS
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.teachers))
                    StatCard(
                      icon: Icons.badge,
                      title: "Teachers",
                      value: teacherCount.toString(),
                      color: Colors.green,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TeacherListScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboard();
                      },
                    ),

                    // ==================================================
                    // SUBJECTS
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.subjects))
                    StatCard(
                      icon: Icons.menu_book,
                      title: "Subjects",
                      value: subjectCount.toString(),
                      color: Colors.orange,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubjectListScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboard();
                      },
                    ),

                    // ==================================================
                    // CLASSES
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.classes))
                    StatCard(
                      icon: Icons.class_,
                      title: "Classes",
                      value: classCount.toString(),
                      color: Colors.orange,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClassListScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboard();
                      },
                    ),

                    // ==================================================
                    // ASSIGN SUBJECTS
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.assignSubjects))
                    StatCard(
                      icon: Icons.assignment,
                      title: "Assign Subjects",
                      value: "Ready",
                      color: Colors.indigo,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClassSubjectDashboardScreen(),
                          ),
                        );
                      },
                    ),

                    // ==================================================
                    // FEES
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.fees))
                    StatCard(
                      icon: Icons.attach_money,
                      title: "Fees",
                      value: "Manage",
                      color: Colors.purple,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeesDashboardScreen(),
                          ),
                        );
                      },
                    ),

                    // ==================================================
                    // RESULTS
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.resultEntry))
                    StatCard(
                      icon: Icons.assignment,
                      title: "Results",
                      value: "Enter",
                      color: Colors.red,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResultEntryScreen(),
                          ),
                        );
                      },
                    ),

                    // ==================================================
                    // BROADSHEET
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.broadsheet))
                    StatCard(
                      icon: Icons.table_chart,
                      title: "Broadsheet",
                      value: "View",
                      color: Colors.deepPurple,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BroadsheetScreen(),
                          ),
                        );
                      },
                    ),

                    // ==================================================
                    // REPORT CARD
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.reportCards))
                    StatCard(
                      icon: Icons.description,
                      title: "Report Card",
                      value: "Generate",
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GenerateReportCardScreen(),
                          ),
                        );
                      },
                    ),
                    // ==================================================
                    // STUDENT PROMOTION
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.promotion))
                    StatCard(
                      icon: Icons.school_outlined,
                      title: "Promotion",
                      value: "Manage",
                      color: Colors.blue.shade800,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentPromotionScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboard();
                      },
                    ),

                    // ==================================================
                    // ANNOUNCEMENTS
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.announcements))
                    StatCard(
                      icon: Icons.campaign,
                      title: "Announcements",
                      value: Permissions.canManageAnnouncements(role)
                          ? "Manage"
                          : "View",
                      color: Colors.teal,
                      onTap: openAnnouncements,
                    ),

                    // ==================================================
                    // FINANCIAL REPORTS
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.fees))
                    StatCard(
                      icon: Icons.bar_chart,
                      title: "Financial Reports",
                      value: "View",
                      color: Colors.green.shade700,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FinancialReportsScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboard();
                      },
                    ),

                    // ==================================================
                    // ATTENDANCE
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.attendance))
                    StatCard(
                      icon: Icons.fact_check,
                      title: "Attendance",
                      value: "Manage",
                      color: Colors.blue.shade700,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboard();
                      },
                    ),

                    // ==================================================
                    // TIMETABLE
                    // ==================================================
                    if (Permissions.canAccess(role, Permissions.timetable))
                    StatCard(
                      icon: Icons.calendar_month,
                      title: "Timetable",
                      value: Permissions.canConfigureTimetable(role)
                          ? "Manage"
                          : "View",
                      color: Colors.deepOrange,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TimetableScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboard();
                      },
                    ),
                    // Configure only for admin / principal
                    if (Permissions.canConfigureTimetable(role))
                    StatCard(
                      icon: Icons.settings,
                      title: "Timetable Settings",
                      value: "Configure",
                      color: Colors.blueGrey,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TimetableSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _announcementController.dispose();

    super.dispose();
  }
}

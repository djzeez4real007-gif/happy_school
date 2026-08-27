import 'package:flutter/material.dart';

import '../core/permissions.dart';
import '../models/app_user.dart';
import '../screens/announcements/announcement_list_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/classes/class_list_screen.dart';
import '../screens/classes/class_subject_dashboard_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/fees/fees_dashboard_screen.dart';
import '../screens/promotion/student_promotion_screen.dart';
import '../screens/report_card/generate_report_card_screen.dart';
import '../screens/results/broadsheet_screen.dart';
import '../screens/results/class_term_averages_screen.dart';
import '../screens/results/result_entry_screen.dart';
import '../screens/students/alumni_list_screen.dart';
import '../screens/subjects/subject_list_screen.dart';
import '../screens/timetable/timetable_hub_screen.dart';
import '../screens/users/user_list_screen.dart';
import '../screens/parent/parent_portal_screen.dart';
import '../screens/audit/audit_log_screen.dart';
import '../screens/media/media_settings_screen.dart';
import '../screens/teachers/my_teaching_screen.dart';
import '../screens/student_portal/student_portal_home_screen.dart';
import '../screens/student_portal/student_portal_admin_screen.dart';
import '../screens/student_portal/student_results_screen.dart';
import '../screens/timetable/timetable_screen.dart';
import '../screens/teachers/assign_teacher_subjects_screen.dart';
import '../services/auth_service.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/premium_feedback.dart';
import '../screens/register/register_hub_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _NavItem {
  final String key;
  final String label;
  final IconData icon;
  final Widget page;
  final String? section;

  const _NavItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.page,
    this.section,
  });
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color sidebarBg = Color(0xFF0F172A);
  static const double sidebarWidth = 260;

  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _menuAnim;

  @override
  void initState() {
    super.initState();
    _menuAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _menuAnim.dispose();
    super.dispose();
  }

  static const List<_NavItem> _allItems = [
    // ── MAIN ──────────────────────────────────────────
    _NavItem(
      key: Permissions.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      page: DashboardScreen(),
      section: 'MAIN',
    ),
    _NavItem(
      key: Permissions.myTeaching,
      label: 'My Teaching',
      icon: Icons.school_rounded,
      page: MyTeachingScreen(),
      section: 'MAIN',
    ),

    // ── STUDENT PORTAL ────────────────────────────────
    _NavItem(
      key: Permissions.studentPortal,
      label: 'Student home',
      icon: Icons.person_rounded,
      page: StudentPortalHomeScreen(),
      section: 'STUDENT',
    ),
    _NavItem(
      key: Permissions.studentPortal,
      label: 'My results',
      icon: Icons.assessment_rounded,
      page: StudentResultsScreen(),
      section: 'STUDENT',
    ),
    _NavItem(
      key: Permissions.studentPortal,
      label: 'Class timetable',
      icon: Icons.calendar_view_week_rounded,
      page: TimetableScreen(),
      section: 'STUDENT',
    ),

    // ── PARENT ────────────────────────────────────────
    _NavItem(
      key: Permissions.parentPortal,
      label: 'My Children',
      icon: Icons.family_restroom_rounded,
      page: ParentPortalScreen(),
      section: 'PARENT',
    ),

    // ── REGISTER ──────────────────────────────────────
    _NavItem(
      key: Permissions.students,
      label: 'Register',
      icon: Icons.app_registration_rounded,
      page: RegisterHubScreen(),
      section: 'REGISTER',
    ),

    // ── ACADEMICS ─────────────────────────────────────
    _NavItem(
      key: Permissions.classes,
      label: 'Classes',
      icon: Icons.class_rounded,
      page: ClassListScreen(),
      section: 'ACADEMICS',
    ),
    _NavItem(
      key: Permissions.subjects,
      label: 'Subjects',
      icon: Icons.menu_book_rounded,
      page: SubjectListScreen(),
      section: 'ACADEMICS',
    ),
    _NavItem(
      key: Permissions.assignSubjects,
      label: 'Assign subjects to class',
      icon: Icons.assignment_rounded,
      page: ClassSubjectDashboardScreen(),
      section: 'ACADEMICS',
    ),
    _NavItem(
      key: Permissions.assignTeacherSubjects,
      label: 'Assign subjects to teacher',
      icon: Icons.assignment_ind_rounded,
      page: AssignTeacherSubjectsScreen(),
      section: 'ACADEMICS',
    ),
    _NavItem(
      key: Permissions.alumni,
      label: 'Alumni',
      icon: Icons.workspace_premium_rounded,
      page: AlumniListScreen(),
      section: 'ACADEMICS',
    ),

    // ── RESULTS ───────────────────────────────────────
    _NavItem(
      key: Permissions.resultEntry,
      label: 'Result Entry',
      icon: Icons.edit_note_rounded,
      page: ResultEntryScreen(),
      section: 'RESULTS',
    ),
    _NavItem(
      key: Permissions.broadsheet,
      label: 'Broadsheet',
      icon: Icons.table_chart_rounded,
      page: BroadsheetScreen(),
      section: 'RESULTS',
    ),
    _NavItem(
      key: Permissions.classAverages,
      label: 'Term Averages',
      icon: Icons.insights_rounded,
      page: ClassTermAveragesScreen(),
      section: 'RESULTS',
    ),
    _NavItem(
      key: Permissions.reportCards,
      label: 'Report Cards',
      icon: Icons.description_rounded,
      page: GenerateReportCardScreen(),
      section: 'RESULTS',
    ),
    _NavItem(
      key: Permissions.promotion,
      label: 'Promotion',
      icon: Icons.trending_up_rounded,
      page: StudentPromotionScreen(),
      section: 'RESULTS',
    ),

    // ── OPERATIONS ────────────────────────────────────
    _NavItem(
      key: Permissions.attendance,
      label: 'Attendance',
      icon: Icons.fact_check_rounded,
      page: AttendanceScreen(),
      section: 'OPERATIONS',
    ),
    _NavItem(
      key: Permissions.timetable,
      label: 'Timetable',
      icon: Icons.calendar_month_rounded,
      page: TimetableHubScreen(),
      section: 'OPERATIONS',
    ),
    _NavItem(
      key: Permissions.announcements,
      label: 'Announcements',
      icon: Icons.campaign_rounded,
      page: AnnouncementListScreen(),
      section: 'OPERATIONS',
    ),

    // ── FEES ──────────────────────────────────────────
    _NavItem(
      key: Permissions.fees,
      label: 'Fees',
      icon: Icons.payments_rounded,
      page: FeesDashboardScreen(),
      section: 'FEES',
    ),

    // ── SYSTEM ────────────────────────────────────────
    _NavItem(
      key: Permissions.studentPortalAdmin,
      label: 'Student portal access',
      icon: Icons.password_rounded,
      page: StudentPortalAdminScreen(),
      section: 'SYSTEM',
    ),
    _NavItem(
      key: Permissions.users,
      label: 'Users & Roles',
      icon: Icons.manage_accounts_rounded,
      page: UserListScreen(),
      section: 'SYSTEM',
    ),
    _NavItem(
      key: Permissions.media,
      label: 'Media',
      icon: Icons.photo_library_rounded,
      page: MediaSettingsScreen(),
      section: 'SYSTEM',
    ),
    _NavItem(
      key: Permissions.auditLog,
      label: 'Audit Log',
      icon: Icons.history_rounded,
      page: AuditLogScreen(),
      section: 'SYSTEM',
    ),
  ];

  List<_NavItem> get _items {
    final role = AuthService.currentRole;
    return _allItems
        .where((item) => Permissions.canAccess(role, item.key))
        .toList();
  }

  void _select(int index) {
    if (index < 0) return;
    setState(() => _selectedIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scaffold = _scaffoldKey.currentState;
      if (scaffold != null && scaffold.isDrawerOpen) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _logout() async {
    final ok = await PremiumFeedback.confirm(
      context,
      title: 'Logout',
      message: 'Sign out of Happy School ERP?\nYou can sign back in anytime.',
      confirmText: 'Logout',
      cancelText: 'Stay',
      icon: Icons.logout_rounded,
      isDestructive: true,
    );

    if (ok) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (_selectedIndex >= items.length) {
      _selectedIndex = 0;
    }

    final isDashboard = _selectedIndex == 0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: isDashboard ? 'Menu' : 'Back to Dashboard',
          icon: isDashboard
              ? _AnimatedHamburger(animation: _menuAnim)
              : const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (isDashboard) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              setState(() => _selectedIndex = 0);
            }
          },
        ),
        title: Text(
          items.isEmpty ? 'Happy School' : items[_selectedIndex].label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!isDashboard)
            IconButton(
              tooltip: 'Menu',
              icon: _AnimatedHamburger(animation: _menuAnim),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ListenableBuilder(
            listenable: ThemeController.instance,
            builder: (context, _) {
              final dark = ThemeController.instance.isDark;
              return IconButton(
                tooltip: dark ? 'Light mode' : 'Dark mode',
                onPressed: () => ThemeController.instance.toggleDark(),
                icon: Icon(
                  dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: sidebarBg,
        child: SafeArea(child: _buildSidebarBody(items)),
      ),
      body: _buildContent(items),
    );
  }

  Widget _buildContent(List<_NavItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No access'));
    }
    return IndexedStack(
      index: _selectedIndex,
      children: items.map((item) => item.page).toList(),
    );
  }

  Widget _buildSidebarBody(List<_NavItem> items) {
    final user = AuthService.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Happy School',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'ERP System',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (user != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryBlue.withValues(alpha: 0.3),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        AppUser.roleLabel(user.role),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(color: Colors.white12, height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = index == _selectedIndex;
              final prevSection =
                  index > 0 ? items[index - 1].section : null;
              final showSection = item.section != null &&
                  item.section != prevSection;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSection) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        top: index == 0 ? 4 : 14,
                        bottom: 6,
                      ),
                      child: Text(
                        item.section!,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                  Material(
                    color: selected
                        ? primaryBlue.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _select(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(
                                  color: primaryBlue.withValues(alpha: 0.5),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: selected ? Colors.white : Colors.white70,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (selected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF60A5FA),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: ListenableBuilder(
            listenable: ThemeController.instance,
            builder: (context, _) {
              final dark = ThemeController.instance.isDark;
              return SwitchListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  dark ? 'Dark mode' : 'Light mode',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                secondary: Icon(
                  dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                value: dark,
                activeThumbColor: const Color(0xFF60A5FA),
                onChanged: (_) => ThemeController.instance.toggleDark(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18, color: Colors.white70),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white70),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              foregroundColor: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

/// Three animated horizontal lines (hamburger) for the sidebar menu.
class _AnimatedHamburger extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedHamburger({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        // Stagger line widths / opacity for a soft pulse
        double w(double phase) {
          final v = ((t + phase) % 1.0);
          final wave = (v < 0.5) ? (v * 2) : (2 - v * 2);
          return 12.0 + wave * 6.0; // 12 → 18
        }

        Widget line(double width, {double opacity = 1}) {
          return Container(
            height: 2.0,
            width: width,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }

        // IconButton constraint is ~24; keep well under to avoid overflow.
        return SizedBox(
          width: 22,
          height: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line(w(0.0), opacity: 0.95),
              line(w(0.33), opacity: 1.0),
              line(w(0.66), opacity: 0.95),
            ],
          ),
        );
      },
    );
  }
}

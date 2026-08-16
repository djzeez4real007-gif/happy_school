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
import '../screens/results/result_entry_screen.dart';
import '../screens/students/student_menu_screen.dart';
import '../screens/subjects/subject_list_screen.dart';
import '../screens/teachers/teacher_list_screen.dart';
import '../screens/timetable/timetable_screen.dart';
import '../screens/users/user_list_screen.dart';
import '../screens/parent/parent_portal_screen.dart';
import '../screens/audit/audit_log_screen.dart';
import '../services/auth_service.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/premium_feedback.dart';

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

class _AppShellState extends State<AppShell> {
  static const Color primaryBlue = Color(0xFF1D4ED8);
  static const Color sidebarBg = Color(0xFF0F172A);
  static const double sidebarWidth = 260;

  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavItem> _allItems = [
    _NavItem(
      key: Permissions.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_rounded,
      page: DashboardScreen(),
      section: 'MAIN',
    ),
    _NavItem(
      key: Permissions.students,
      label: 'Students',
      icon: Icons.people_alt_rounded,
      page: StudentMenuScreen(),
      section: 'ACADEMICS',
    ),
    _NavItem(
      key: Permissions.teachers,
      label: 'Teachers',
      icon: Icons.badge_rounded,
      page: TeacherListScreen(),
    ),
    _NavItem(
      key: Permissions.classes,
      label: 'Classes',
      icon: Icons.class_rounded,
      page: ClassListScreen(),
    ),
    _NavItem(
      key: Permissions.subjects,
      label: 'Subjects',
      icon: Icons.menu_book_rounded,
      page: SubjectListScreen(),
    ),
    _NavItem(
      key: Permissions.assignSubjects,
      label: 'Assign Subjects',
      icon: Icons.assignment_rounded,
      page: ClassSubjectDashboardScreen(),
    ),
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
    ),
    _NavItem(
      key: Permissions.reportCards,
      label: 'Report Cards',
      icon: Icons.description_rounded,
      page: GenerateReportCardScreen(),
    ),
    _NavItem(
      key: Permissions.promotion,
      label: 'Promotion',
      icon: Icons.trending_up_rounded,
      page: StudentPromotionScreen(),
    ),
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
      page: TimetableScreen(),
    ),
    _NavItem(
      key: Permissions.fees,
      label: 'Fees',
      icon: Icons.payments_rounded,
      page: FeesDashboardScreen(),
    ),
    _NavItem(
      key: Permissions.announcements,
      label: 'Announcements',
      icon: Icons.campaign_rounded,
      page: AnnouncementListScreen(),
    ),
    _NavItem(
      key: Permissions.users,
      label: 'Users & Roles',
      icon: Icons.manage_accounts_rounded,
      page: UserListScreen(),
      section: 'SYSTEM',
    ),
    _NavItem(
      key: Permissions.parentPortal,
      label: 'My Children',
      icon: Icons.family_restroom_rounded,
      page: ParentPortalScreen(),
      section: 'PARENT',
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
    setState(() => _selectedIndex = index);
    if (Scaffold.maybeOf(context)?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
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

    // Drawer navigation — not a fixed sidebar
    // On non-dashboard pages, leading is Back (to Dashboard).
    // Menu is always available via the drawer icon on Dashboard,
    // and via the menu button in actions on other pages.
    final isDashboard = _selectedIndex == 0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: isDashboard ? 'Menu' : 'Back to Dashboard',
          icon: Icon(isDashboard ? Icons.menu_rounded : Icons.arrow_back_rounded),
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
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ListenableBuilder(
            listenable: ThemeController.instance,
            builder: (context, _) {
              final dark = ThemeController.instance.isDark;
              return IconButton(
                tooltip: dark ? 'Light mode' : 'Dark mode',
                onPressed: () => ThemeController.instance.toggleDark(),
                icon: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
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

  Widget _buildSidebar(List<_NavItem> items) {
    return Container(
      width: sidebarWidth,
      color: sidebarBg,
      child: SafeArea(child: _buildSidebarBody(items)),
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

        // Current user
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.section != null) ...[
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
                                  color:
                                      selected ? Colors.white : Colors.white70,
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
                activeColor: const Color(0xFF60A5FA),
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

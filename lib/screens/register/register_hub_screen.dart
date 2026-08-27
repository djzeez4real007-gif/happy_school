import 'package:flutter/material.dart';

import '../../core/permissions.dart';
import '../../services/auth_service.dart';
import '../students/student_menu_screen.dart';
import '../teachers/teacher_list_screen.dart';
import '../staff/non_teaching_staff_list_screen.dart';

/// Single sidebar entry → choose Register Student / Teachers / Staff.
class RegisterHubScreen extends StatelessWidget {
  const RegisterHubScreen({super.key});

  static const Color primaryBlue = Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    final role = AuthService.currentRole;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = <_RegOption>[
      if (Permissions.canAccess(role, Permissions.students))
        _RegOption(
          title: 'Register Student',
          subtitle: 'New students, profiles, class assignment',
          icon: Icons.person_add_alt_1_rounded,
          color: primaryBlue,
          page: const StudentMenuScreen(),
        ),
      if (Permissions.canAccess(role, Permissions.teachers))
        _RegOption(
          title: 'Teachers',
          subtitle: 'Teaching staff registration and list',
          icon: Icons.badge_rounded,
          color: const Color(0xFF0F766E),
          page: const TeacherListScreen(),
        ),
      if (Permissions.canAccess(role, Permissions.teachers))
        _RegOption(
          title: 'Non-Teaching Staff',
          subtitle: 'Admin, support and other staff',
          icon: Icons.engineering_rounded,
          color: const Color(0xFFD97706),
          page: const NonTeachingStaffListScreen(),
        ),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Register',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose what you want to register',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          if (options.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('You do not have permission to register.'),
              ),
            )
          else
            ...options.map((o) => _card(context, o, isDark)),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, _RegOption o, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: isDark ? 0 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => o.page));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: o.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(o.icon, color: o.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  _RegOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import 'student_registration_screen.dart';
import 'student_list_screen.dart';
import 'student_class_assignment_screen.dart';
import 'student_class_list_screen.dart';
import 'unassigned_students_screen.dart';

class StudentMenuScreen extends StatelessWidget {
  const StudentMenuScreen({super.key});

  

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Register Student',
        subtitle: 'Add a new student to the school',
        color: const Color(0xFF2563EB),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.groups_rounded,
        title: 'Student List',
        subtitle: 'View and manage all students',
        color: const Color(0xFF7C3AED),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentListScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.school_rounded,
        title: 'Assign to Class',
        subtitle: 'Place a student into a class & session',
        color: const Color(0xFF059669),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentClassAssignmentScreen(),
          ),
        ),
      ),
      _MenuItem(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Assigned Students',
        subtitle: 'Students already placed in classes',
        color: const Color(0xFFD97706),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentClassListScreen()),
        ),
      ),
      _MenuItem(
        icon: Icons.person_off_outlined,
        title: 'Unassigned Students',
        subtitle: 'Registered but not yet in any class',
        color: const Color(0xFFDC2626),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UnassignedStudentsScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Students',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Registration · Class placement · Records',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : 12,
                    ),
                    child: _PremiumMenuCard(item: items[index]),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _PremiumMenuCard extends StatelessWidget {
  final _MenuItem item;

  const _PremiumMenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

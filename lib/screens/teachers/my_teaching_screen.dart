import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/teacher.dart';
import '../../models/teacher_subject.dart';
import '../../services/auth_service.dart';
import '../../services/subject_teacher_service.dart';
import '../results/result_entry_screen.dart';
import '../timetable/timetable_screen.dart';

class MyTeachingScreen extends StatefulWidget {
  const MyTeachingScreen({super.key});

  @override
  State<MyTeachingScreen> createState() => _MyTeachingScreenState();
}

class _MyTeachingScreenState extends State<MyTeachingScreen> {
  bool loading = true;
  Teacher? me;
  List<TeacherSubject> subjects = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final teacher = await SubjectTeacherService.linkedTeacher();
      final raw = await SubjectTeacherService.mySubjects();
      final seen = <String>{};
      final list = <TeacherSubject>[];
      for (final s in raw) {
        final c = s.subjectCode.trim().toLowerCase();
        if (c.isEmpty || seen.contains(c)) continue;
        seen.add(c);
        list.add(s);
      }
      list.sort((a, b) => a.subjectName.compareTo(b.subjectName));
      if (!mounted) return;
      setState(() {
        me = teacher;
        subjects = list;
        loading = false;
        if (SubjectTeacherService.linkedStaffId == null) {
          error =
              'Your login is not linked to a teacher profile. Ask admin to set “Linked teacher” on your user account.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = me?.fullName ?? AuthService.currentName;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Teaching',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.isEmpty ? 'Subject teacher' : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        if (me != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${me!.staffId} · ${me!.employmentType}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          '${subjects.length} subject(s) assigned to you',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _action(
                          Icons.edit_note_rounded,
                          'Enter results',
                          'Only your subjects',
                          const Color(0xFF2563EB),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResultEntryScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _action(
                          Icons.calendar_view_week_rounded,
                          'My timetable',
                          'Your periods',
                          const Color(0xFF059669),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TimetableScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your subjects',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set by admin under “Assign subjects to teacher”',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(error!),
                    )
                  else if (subjects.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder(context)),
                      ),
                      child: Text(
                        'No subjects assigned yet.\nAdmin should open Assign subjects to teacher and tick your subjects.',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    ...subjects.map(
                      (s) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.cardBorder(context)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu_book_rounded,
                                  color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.subjectName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    s.subjectCode,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _action(
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

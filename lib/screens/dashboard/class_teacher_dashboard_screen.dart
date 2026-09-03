import 'package:flutter/material.dart';
import '../../widgets/announcement_marquee.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../services/attendance_storage.dart';
import '../../services/auth_service.dart';
import '../../services/class_storage.dart';
import '../../services/student_class_storage.dart';
import '../attendance/attendance_screen.dart';
import '../results/result_entry_screen.dart';
import '../results/broadsheet_screen.dart';
import '../timetable/timetable_screen.dart';

class ClassTeacherDashboardScreen extends StatefulWidget {
  const ClassTeacherDashboardScreen({super.key});

  @override
  State<ClassTeacherDashboardScreen> createState() =>
      _ClassTeacherDashboardScreenState();
}

class _ClassTeacherDashboardScreenState
    extends State<ClassTeacherDashboardScreen> {
  bool loading = true;
  List<String> myClasses = [];
  int studentsInClasses = 0;
  int presentToday = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final staffId = AuthService.currentUser?.linkedTeacherId?.trim() ?? '';
    final names = <String>[];
    try {
      final classes = await ClassStorage.getClasses();
      for (final c in classes) {
        if (staffId.isNotEmpty && c.teacherId == staffId) {
          names.add(c.fullClassName);
        }
      }
    } catch (_) {}

    int count = 0;
    final session = Sessions.current();
    try {
      final assigns = await StudentClassStorage.getStudents();
      final lower = names.map((e) => e.trim().toLowerCase()).toSet();
      for (final a in assigns) {
        if (a.session.trim() != session.trim()) continue;
        if (lower.contains(a.className.trim().toLowerCase())) count++;
      }
    } catch (_) {}

    int present = 0;
    try {
      final now = DateTime.now();
      final key =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final records = await AttendanceStorage.getAttendance();
      final classSet = names.map((e) => e.trim().toLowerCase()).toSet();
      for (final r in records) {
        final d = r.date.toString().trim();
        final st = r.status.toString().toLowerCase();
        final cn = r.className.toString().trim().toLowerCase();
        if (!d.startsWith(key)) continue;
        if (classSet.isNotEmpty && !classSet.contains(cn)) continue;
        if (st.contains('present')) present++;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      myClasses = names;
      studentsInClasses = count;
      presentToday = present;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.currentName;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Class teacher',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          name.isEmpty ? 'Teacher' : name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          myClasses.isEmpty
                              ? 'No class linked — ask admin to set you as class teacher'
                              : 'Class(es): ${myClasses.join(', ')}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const AnnouncementMarquee(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stat('Students', '$studentsInClasses',
                            'In your class(es)'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _stat(
                            'Present today', '$presentToday', 'Marked present'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Quick actions',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const SizedBox(height: 10),
                  _link(Icons.edit_note_rounded, 'Enter results', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ResultEntryScreen()),
                    );
                  }),
                  _link(Icons.table_chart_rounded, 'Broadsheet', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BroadsheetScreen()),
                    );
                  }),
                  _link(Icons.fact_check_rounded, 'Attendance', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AttendanceScreen()),
                    );
                  }),
                  _link(Icons.calendar_view_week_rounded, 'Timetable', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TimetableScreen()),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _stat(String t, String v, String s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 12)),
          Text(v,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          Text(s,
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary(context))),
        ],
      ),
    );
  }

  Widget _link(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

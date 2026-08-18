
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../services/student_status_service.dart';
import '../../services/student_storage.dart';
import 'student_details_screen.dart';

/// Alumni (graduated SS3) and students who left without returning.
class AlumniListScreen extends StatefulWidget {
  const AlumniListScreen({super.key});

  @override
  State<AlumniListScreen> createState() => _AlumniListScreenState();
}

class _AlumniListScreenState extends State<AlumniListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool loading = true;
  String query = '';
  List<StudentClass> graduated = [];
  List<StudentClass> left = [];
  Map<String, Student> byAdmission = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final g = await StudentStatusService.allGraduatedAssignments();
    final l = await StudentStatusService.allLeftAssignments();
    final students = await StudentStorage.getStudents();
    final map = {
      for (final s in students) s.admissionNo.trim().toLowerCase(): s,
    };
    if (!mounted) return;
    setState(() {
      graduated = g;
      left = l;
      byAdmission = map;
      loading = false;
    });
  }

  List<StudentClass> _filter(List<StudentClass> source) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((a) {
      final s = byAdmission[a.admissionNo.trim().toLowerCase()];
      final name = s?.fullName ?? a.studentName;
      return name.toLowerCase().contains(q) ||
          a.admissionNo.toLowerCase().contains(q) ||
          a.session.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('Alumni & Former'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Graduated (${graduated.length})'),
            Tab(text: 'Left school (${left.length})'),
          ],
        ),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search name, admission no, session…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _list(
                        _filter(graduated),
                        empty:
                            'No graduated students yet.\nUse Promotion → SS3 → Graduated.',
                        badge: 'GRADUATED',
                        badgeColor: const Color(0xFF059669),
                        badgeBg: const Color(0xFFD1FAE5),
                      ),
                      _list(
                        _filter(left),
                        empty:
                            'No students marked as left.\nUse Promotion → Left school (did not return).',
                        badge: 'LEFT',
                        badgeColor: const Color(0xFF64748B),
                        badgeBg: const Color(0xFFF1F5F9),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    List<StudentClass> list, {
    required String empty,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    if (list.isEmpty) {
      return Center(child: Text(empty, textAlign: TextAlign.center));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final a = list[index];
        final s = byAdmission[a.admissionNo.trim().toLowerCase()];
        final name = s?.fullName ?? a.studentName;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder(context)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: badgeColor.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800),
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${a.admissionNo}\n${a.session}'),
            isThreeLine: true,
            trailing: Chip(
              label: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
              backgroundColor: badgeBg,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onTap: s == null
                ? null
                : () async {
                    final students = await StudentStorage.getStudents();
                    final idx = students.indexWhere(
                      (x) =>
                          x.admissionNo.trim().toLowerCase() ==
                          s.admissionNo.trim().toLowerCase(),
                    );
                    if (!context.mounted || idx < 0) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentDetailsScreen(student: s, index: idx),
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}

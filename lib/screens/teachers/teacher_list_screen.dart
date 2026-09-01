import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/teacher.dart';
import '../../services/teacher_storage.dart';
import 'teacher_registration_screen.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  List<Teacher> teachers = [];
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = await TeacherStorage.getTeachers();
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    if (!mounted) return;
    setState(() {
      teachers = list;
      loading = false;
    });
  }

  List<Teacher> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return teachers;
    return teachers
        .where((t) =>
            t.fullName.toLowerCase().contains(q) ||
            t.phone.contains(q) ||
            t.department.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _delete(Teacher t, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete teacher'),
        content: Text('Delete ${t.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await TeacherStorage.deleteTeacher(index);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text('Teachers (${teachers.length})'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherRegistrationScreen()),
          );
          await _load();
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add teacher'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'Search teachers…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text('No teachers yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final t = list[i];
                          final realIndex = teachers.indexWhere(
                            (x) => x.fullName == t.fullName && x.phone == t.phone,
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text(
                                [
                                  if (t.department.isNotEmpty) t.department,
                                  if (t.employmentType.isNotEmpty) t.employmentType,
                                  t.phone,
                                ].where((e) => e.toString().trim().isNotEmpty).join(' · '),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: realIndex >= 0
                                    ? () => _delete(t, realIndex)
                                    : null,
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherRegistrationScreen(
                                      teacher: t,
                                      index: realIndex >= 0 ? realIndex : null,
                                    ),
                                  ),
                                );
                                await _load();
                              },
                            ),
                          );
                        },
                      ),
                  ),
        ],
      ),
    );
  }
}

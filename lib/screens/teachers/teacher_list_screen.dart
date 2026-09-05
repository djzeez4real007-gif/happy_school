import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/teacher.dart';
import '../../services/teacher_storage.dart';
import 'staff_id_card_preview_screen.dart';
import 'teacher_registration_screen.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  List<Teacher> teachers = [];
  Map<String, int> staffIndex = {};
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
    final idxMap = <String, int>{};
    for (int i = 0; i < list.length; i++) {
      idxMap[list[i].staffId.trim().toLowerCase()] = i;
    }
    list.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    if (!mounted) return;
    setState(() {
      teachers = list;
      staffIndex = idxMap;
      loading = false;
    });
  }

  List<Teacher> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return teachers;
    return teachers
        .where((t) =>
            t.fullName.toLowerCase().contains(q) ||
            t.staffId.toLowerCase().contains(q) ||
            t.phone.contains(q) ||
            t.department.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _delete(Teacher t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete teacher'),
        content: Text('Delete ${t.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await TeacherStorage.deleteTeacherByStaffId(t.staffId);
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TeacherRegistrationScreen()),
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
                          // Always resolve Hive index by unique staffId
                          final hiveIndex = staffIndex[t.staffId.trim().toLowerCase()] ?? -1;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                t.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                [
                                  t.staffId,
                                  if (t.department.isNotEmpty) t.department,
                                  if (t.employmentType.isNotEmpty)
                                    t.employmentType,
                                  t.phone,
                                ]
                                    .where((e) => e.toString().trim().isNotEmpty)
                                    .join(' · '),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'ID card',
                                    icon: Icon(Icons.badge_outlined,
                                        color: AppColors.primary),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              StaffIdCardPreviewScreen(
                                                  teacher: t),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _delete(t),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherRegistrationScreen(
                                      teacher: t,
                                      index:
                                          hiveIndex >= 0 ? hiveIndex : null,
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

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../models/teacher_subject.dart';
import '../../services/subject_storage.dart';
import '../../services/teacher_storage.dart';
import '../../services/teacher_subject_storage.dart';

/// Assign one or more subjects to a teacher (not class-wide).
class AssignTeacherSubjectsScreen extends StatefulWidget {
  const AssignTeacherSubjectsScreen({super.key});

  @override
  State<AssignTeacherSubjectsScreen> createState() =>
      _AssignTeacherSubjectsScreenState();
}

class _AssignTeacherSubjectsScreenState
    extends State<AssignTeacherSubjectsScreen> {
  bool loading = true;
  bool saving = false;
  List<Teacher> teachers = [];
  List<Subject> subjects = [];
  Teacher? selectedTeacher;
  final Set<String> selectedCodes = {};
  String search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final t = await TeacherStorage.getTeachers();
    t.sort((a, b) => a.fullName.compareTo(b.fullName));
    final raw = await SubjectStorage.getSubjects();
    final seen = <String>{};
    final s = <Subject>[];
    for (final x in raw) {
      final code = x.subjectCode.trim().toLowerCase();
      final key = code.isNotEmpty ? code : x.subjectName.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      s.add(x);
    }
    s.sort((a, b) => a.subjectName.compareTo(b.subjectName));
    if (!mounted) return;
    setState(() {
      teachers = t;
      subjects = s;
      loading = false;
    });
  }

  Future<void> _onTeacherSelected(Teacher? teacher) async {
    setState(() {
      selectedTeacher = teacher;
      selectedCodes.clear();
    });
    if (teacher == null) return;
    final existing =
        await TeacherSubjectStorage.forTeacher(teacher.staffId);
    if (!mounted) return;
    setState(() {
      selectedCodes
        ..clear()
        ..addAll(existing.map((e) => e.subjectCode.trim().toLowerCase()));
    });
  }

  Future<void> _save() async {
    final teacher = selectedTeacher;
    if (teacher == null) {
      PremiumFeedback.error(context,
          title: 'Select a teacher', subtitle: 'Choose who to assign subjects to');
      return;
    }
    setState(() => saving = true);
    final list = subjects
        .where(
            (s) => selectedCodes.contains(s.subjectCode.trim().toLowerCase()))
        .map(
          (s) => TeacherSubject(
            teacherId: teacher.staffId,
            subjectCode: s.subjectCode,
            subjectName: s.subjectName,
          ),
        )
        .toList();
    await TeacherSubjectStorage.setForTeacher(teacher.staffId, list);
    if (!mounted) return;
    setState(() => saving = false);
    PremiumFeedback.success(
      context,
      title: 'Subjects saved',
      subtitle:
          '${teacher.fullName}: ${list.length} subject(s)',
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = teachers.where((t) {
      if (search.trim().isEmpty) return true;
      final q = search.trim().toLowerCase();
      return t.fullName.toLowerCase().contains(q) ||
          t.staffId.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('Assign subjects to teacher'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'SAVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Teacher list
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search teacher…',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => search = v),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredTeachers.length,
                          itemBuilder: (context, i) {
                            final t = filteredTeachers[i];
                            final selected =
                                selectedTeacher?.staffId == t.staffId;
                            return ListTile(
                              selected: selected,
                              selectedTileColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  t.surname.isNotEmpty
                                      ? t.surname[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                t.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              subtitle: Text(
                                t.staffId,
                                style: const TextStyle(fontSize: 11.5),
                              ),
                              onTap: () => _onTeacherSelected(t),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Subject checklist
                Expanded(
                  child: selectedTeacher == null
                      ? Center(
                          child: Text(
                            'Select a teacher on the left,\nthen tick the subject(s) they teach.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              height: 1.4,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFFEFF6FF),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedTeacher!.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                  Text(
                                    'Tick only the subjects this teacher handles (1, 2, or more).',
                                    style: TextStyle(
                                      color: AppColors.textSecondary(context),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${selectedCodes.length} selected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: subjects.length,
                                itemBuilder: (context, i) {
                                  final s = subjects[i];
                                  final code =
                                      s.subjectCode.trim().toLowerCase();
                                  final checked = selectedCodes.contains(code);
                                  return CheckboxListTile(
                                    value: checked,
                                    title: Text(
                                      s.subjectName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(s.subjectCode),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          selectedCodes.add(code);
                                        } else {
                                          selectedCodes.remove(code);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton.icon(
                                onPressed: saving ? null : _save,
                                icon: Icon(Icons.save_rounded),
                                label: const Text('Save subjects for teacher'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

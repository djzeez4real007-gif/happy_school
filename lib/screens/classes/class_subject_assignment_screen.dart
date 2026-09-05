import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../core/widgets/premium_form.dart';
import '../../models/class_subject.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../services/class_storage.dart';
import '../../services/class_subject_storage.dart';
import '../../services/subject_storage.dart';

class ClassSubjectAssignmentScreen extends StatefulWidget {
  /// When set, opens already on this class (edit from dashboard).
  final String? initialClassName;

  const ClassSubjectAssignmentScreen({super.key, this.initialClassName});

  @override
  State<ClassSubjectAssignmentScreen> createState() =>
      _ClassSubjectAssignmentScreenState();
}

class _ClassSubjectAssignmentScreenState
    extends State<ClassSubjectAssignmentScreen> {
  List<SchoolClass> classes = [];
  List<Subject> subjects = [];
  SchoolClass? selectedClass;
  final Set<String> selectedSubjects = {};
  bool saving = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    classes = await ClassStorage.getClasses();
    subjects = await SubjectStorage.getSubjects();

    final initial = widget.initialClassName?.trim();
    if (initial != null && initial.isNotEmpty) {
      try {
        selectedClass = classes.firstWhere(
          (c) => c.fullClassName.trim().toLowerCase() == initial.toLowerCase(),
        );
      } catch (_) {
        try {
          selectedClass = classes.firstWhere(
            (c) => c.fullClassName.trim().toLowerCase().contains(initial.toLowerCase()),
          );
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() => loading = false);
    if (selectedClass != null) {
      await loadAssignedSubjects();
    }
  }

  Future<void> loadAssignedSubjects() async {
    if (selectedClass == null) return;
    final assigned =
        await ClassSubjectStorage.getClassSubjects(selectedClass!.fullClassName);
    setState(() {
      selectedSubjects
        ..clear()
        ..addAll(assigned.map((e) => e.subjectCode));
    });
  }

  Future<void> saveAssignments() async {
    if (selectedClass == null) {
      PremiumFeedback.info(context, title: 'Select a class first');
      return;
    }
    setState(() => saving = true);
    try {
      await ClassSubjectStorage.deleteClassSubjects(selectedClass!.fullClassName);
      for (final code in selectedSubjects) {
        final subject = subjects.firstWhere((s) => s.subjectCode == code);
        await ClassSubjectStorage.assignSubject(
          ClassSubject(
            className: selectedClass!.fullClassName,
            subjectCode: subject.subjectCode,
            subjectName: subject.subjectName,
            teacherId: '',
          ),
        );
      }
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.success(
        context,
        title: 'Subjects assigned successfully',
        subtitle: '${selectedSubjects.length} subject(s) for ${selectedClass!.fullClassName}',
        icon: Icons.assignment_turned_in_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(context, title: 'Assignment failed', subtitle: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        leading: AppBack.leading(context),
        title: const Text('Assign Subjects'),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      PremiumForm.header(
                        context,
                        title: 'Assign Subjects',
                        subtitle: 'Choose which subjects this class offers',
                        icon: Icons.assignment_rounded,
                        gradient: const [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
                      ),
                      const SizedBox(height: 16),
                      PremiumForm.card(
                        context,
                        children: [
                          DropdownButtonFormField<SchoolClass>(
                            value: selectedClass,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Class',
                              prefixIcon: Icon(Icons.class_rounded),
                            ),
                            items: classes
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.fullClassName),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              setState(() => selectedClass = value);
                              await loadAssignedSubjects();
                            },
                          ),
                          const SizedBox(height: 8),
                          if (selectedClass != null)
                            Text(
                              '${selectedSubjects.length} selected',
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (selectedClass != null)
                        ...subjects.map((subject) {
                          final checked =
                              selectedSubjects.contains(subject.subjectCode);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: checked
                                    ? const Color(0xFF8B5CF6)
                                    : AppColors.cardBorder(context),
                              ),
                            ),
                            child: CheckboxListTile(
                              value: checked,
                              title: Text(
                                subject.subjectName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              subtitle: Text(subject.subjectCode),
                              activeColor: const Color(0xFF7C3AED),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedSubjects.add(subject.subjectCode);
                                  } else {
                                    selectedSubjects
                                        .remove(subject.subjectCode);
                                  }
                                });
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: PremiumForm.primaryButton(
                      label: 'SAVE ASSIGNMENT',
                      onPressed: saveAssignments,
                      loading: saving,
                      icon: Icons.save_rounded,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

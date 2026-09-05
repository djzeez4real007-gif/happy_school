import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';

import '../../core/theme/app_colors.dart';
import '../../data/school_class_levels.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../core/widgets/premium_form.dart';
import '../../models/school_class.dart';
import '../../models/teacher.dart';
import '../../services/class_storage.dart';
import '../../services/teacher_storage.dart';

class ClassRegistrationScreen extends StatefulWidget {
  final SchoolClass? schoolClass;
  final int? index;

  const ClassRegistrationScreen({super.key, this.schoolClass, this.index});

  @override
  State<ClassRegistrationScreen> createState() =>
      _ClassRegistrationScreenState();
}

class _ClassRegistrationScreenState extends State<ClassRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final classTeacherController = TextEditingController();

  String className = 'Primary 1';
  String arm = 'A';
  List<Teacher> teachers = [];
  bool saving = false;

  bool get isEdit => widget.schoolClass != null;

  @override
  void initState() {
    super.initState();
    loadTeachers();
    if (widget.schoolClass != null) {
      className = widget.schoolClass!.className;
      arm = widget.schoolClass!.arm;
      classTeacherController.text = widget.schoolClass!.teacherId;
    }
  }

  Future<void> loadTeachers() async {
    final data = await TeacherStorage.getTeachers();
    if (!mounted) return;
    setState(() => teachers = data);
  }

  @override
  void dispose() {
    classTeacherController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final selectedTeacher = teachers.firstWhere(
        (t) => t.staffId == classTeacherController.text,
      );
      final schoolClass = SchoolClass(
        className: className,
        arm: arm,
        teacherId: selectedTeacher.staffId,
        classTeacher: selectedTeacher.fullName,
        capacity: 0,
      );
      if (isEdit) {
        await ClassStorage.updateClass(widget.index!, schoolClass);
      } else {
        await ClassStorage.addClass(schoolClass);
      }
      if (!mounted) return;
      PremiumFeedback.success(
        context,
        title: isEdit ? 'Class updated' : 'Class added successfully',
        subtitle: schoolClass.fullClassName,
        icon: Icons.class_rounded,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(context, title: 'Could not save class', subtitle: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        leading: AppBack.leading(context),
        title: Text(isEdit ? 'Edit Class' : 'Class Registration'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            PremiumForm.header(
              context,
              title: isEdit ? 'Edit Class' : 'Register Class',
              subtitle: 'Class · Arm · Class teacher',
              icon: Icons.class_rounded,
            ),
            const SizedBox(height: 16),
            PremiumForm.card(
              context,
              children: [
                DropdownButtonFormField<String>(
                  value: className,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                  items: [
                    for (final c in SchoolClassLevels.all)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => className = v);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: arm,
                  decoration: const InputDecoration(
                    labelText: 'Arm',
                    prefixIcon: Icon(Icons.abc_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('A')),
                    DropdownMenuItem(value: 'B', child: Text('B')),
                    DropdownMenuItem(value: 'C', child: Text('C')),
                    DropdownMenuItem(value: 'D', child: Text('D')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => arm = v);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: classTeacherController.text.isEmpty
                      ? null
                      : classTeacherController.text,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Class Teacher',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  items: teachers
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.staffId,
                          child: Text('${t.fullName} (${t.staffId})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => classTeacherController.text = v);
                    }
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Select a class teacher' : null,
                ),
                const SizedBox(height: 22),
                PremiumForm.primaryButton(
                  label: isEdit ? 'UPDATE CLASS' : 'SAVE CLASS',
                  onPressed: _save,
                  loading: saving,
                  icon: Icons.save_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

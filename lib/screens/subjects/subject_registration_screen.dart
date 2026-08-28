import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../core/widgets/premium_form.dart';
import '../../models/subject.dart';
import '../../services/subject_storage.dart';

class SubjectRegistrationScreen extends StatefulWidget {
  final Subject? subject;
  final int? index;

  const SubjectRegistrationScreen({super.key, this.subject, this.index});

  @override
  State<SubjectRegistrationScreen> createState() =>
      _SubjectRegistrationScreenState();
}

class _SubjectRegistrationScreenState extends State<SubjectRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final subjectNameController = TextEditingController();
  final subjectCodeController = TextEditingController();
  String studentClass = 'JSS1';
  bool saving = false;

  final List<String> classes = ['JSS1', 'JSS2', 'JSS3', 'SS1', 'SS2', 'SS3'];
  bool get isEdit => widget.subject != null;

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      subjectNameController.text = widget.subject!.subjectName;
      subjectCodeController.text = widget.subject!.subjectCode;
      studentClass = widget.subject!.studentClass;
    }
  }

  @override
  void dispose() {
    subjectNameController.dispose();
    subjectCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final subject = Subject(
      subjectName: subjectNameController.text.trim(),
      subjectCode: subjectCodeController.text.trim(),
      studentClass: '',
    );
    try {
      if (isEdit) {
        await SubjectStorage.updateSubject(widget.index!, subject);
      } else {
        await SubjectStorage.addSubject(subject);
      }
      if (!mounted) return;
      PremiumFeedback.success(
        context,
        title: isEdit ? 'Subject updated' : 'Subject saved successfully',
        subtitle: subject.subjectName,
        icon: Icons.menu_book_rounded,
      );
      if (isEdit) {
        Navigator.pop(context);
        return;
      }
      _formKey.currentState!.reset();
      subjectNameController.clear();
      subjectCodeController.clear();
      setState(() {
        studentClass = 'JSS1';
        saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(context, title: 'Could not save subject', subtitle: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Subject' : 'Register Subject'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            PremiumForm.header(
              context,
              title: isEdit ? 'Edit Subject' : 'Register Subject',
              subtitle: 'Subject name and code',
              icon: Icons.menu_book_rounded,
              gradient: const [Color(0xFF6D28D9), Color(0xFFA78BFA)],
            ),
            const SizedBox(height: 16),
            PremiumForm.card(
              context,
              children: [
                TextFormField(
                  controller: subjectNameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    prefixIcon: Icon(Icons.menu_book_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter subject name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: subjectCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Code',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter subject code' : null,
                ),
                const SizedBox(height: 22),
                PremiumForm.primaryButton(
                  label: isEdit ? 'UPDATE SUBJECT' : 'SAVE SUBJECT',
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

import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../core/widgets/premium_form.dart';
import '../../models/teacher.dart';
import '../../services/audit_log_storage.dart';
import '../../services/teacher_storage.dart';

class TeacherRegistrationScreen extends StatefulWidget {
  final Teacher? teacher;
  final int? index;

  const TeacherRegistrationScreen({super.key, this.teacher, this.index});

  @override
  State<TeacherRegistrationScreen> createState() =>
      _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState extends State<TeacherRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final staffIdController = TextEditingController();
  final surnameController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  String gender = 'Male';
  String qualification = 'B.Ed';
  String department = 'Science';
  String employmentType = 'Full-time';
  bool saving = false;

  File? passportImage;
  final ImagePicker _picker = ImagePicker();


  bool get isEdit => widget.teacher != null;

  Future<void> generateStaffId() async {
    final teachers = await TeacherStorage.getTeachers();
    final year = DateTime.now().year;
    int count = teachers.where((t) => t.staffId.startsWith('HST/$year/')).length;
    count++;
    staffIdController.text = 'HST/$year/${count.toString().padLeft(4, '0')}';
  }

  @override
  void initState() {
    super.initState();
    if (widget.teacher == null) {
      generateStaffId();
    } else {
      final t = widget.teacher!;
      staffIdController.text = t.staffId;
      surnameController.text = t.surname;
      firstNameController.text = t.firstName;
      middleNameController.text = t.middleName;
      phoneController.text = t.phone;
      emailController.text = t.email;
      addressController.text = t.address;
      gender = t.gender;
      qualification = t.qualification;
      department = t.department;
      employmentType = t.employmentType.isNotEmpty ? t.employmentType : 'Full-time';
    }
  }

  @override
  void dispose() {
    staffIdController.dispose();
    surnameController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> pickPassport() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (image == null) return;
    setState(() => passportImage = File(image.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final teacher = Teacher(
      staffId: staffIdController.text.trim(),
      surname: surnameController.text.trim(),
      firstName: firstNameController.text.trim(),
      middleName: middleNameController.text.trim(),
      gender: gender,
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
      qualification: qualification,
      department: department,
      passport: passportImage?.path ?? '',
      employmentType: employmentType,
    );
    try {
      if (isEdit) {
        await TeacherStorage.updateTeacher(widget.index!, teacher);
        await AuditLogStorage.log(
          action: 'teacher_updated',
          module: 'teachers',
          description: 'Updated teacher ${teacher.fullName}',
          refId: teacher.staffId,
        );
      } else {
        await TeacherStorage.addTeacher(teacher);
        await AuditLogStorage.log(
          action: 'teacher_added',
          module: 'teachers',
          description: 'Registered teacher ${teacher.fullName}',
          refId: teacher.staffId,
        );
      }
      if (!mounted) return;
      PremiumFeedback.success(
        context,
        title: isEdit ? 'Teacher updated' : 'Teacher registered successfully',
        subtitle: teacher.fullName,
        icon: Icons.person_add_alt_1_rounded,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(context, title: 'Could not save teacher', subtitle: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        leading: AppBack.leading(context),
        title: Text(isEdit ? 'Edit Teacher' : 'Teacher Registration'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            PremiumForm.header(
              context,
              title: isEdit ? 'Edit Teacher' : 'Register Teacher',
              subtitle: 'Staff profile and department',
              icon: Icons.badge_rounded,
              gradient: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
            ),
            const SizedBox(height: 16),
            PremiumForm.card(
              context,
              children: [
                TextFormField(
                  controller: staffIdController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Staff ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: surnameController,
                  decoration: const InputDecoration(
                    labelText: 'Surname',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: middleNameController,
                  decoration: const InputDecoration(
                    labelText: 'Middle Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => gender = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: qualification,
                  decoration: const InputDecoration(
                    labelText: 'Qualification',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NCE', child: Text('NCE')),
                    DropdownMenuItem(value: 'B.Ed', child: Text('B.Ed')),
                    DropdownMenuItem(value: 'B.Sc', child: Text('B.Sc')),
                    DropdownMenuItem(value: 'M.Ed', child: Text('M.Ed')),
                    DropdownMenuItem(value: 'PhD', child: Text('PhD')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => qualification = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: department,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.apartment_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Science', child: Text('Science')),
                    DropdownMenuItem(value: 'Arts', child: Text('Arts')),
                    DropdownMenuItem(
                        value: 'Commercial', child: Text('Commercial')),
                    DropdownMenuItem(
                        value: 'Languages', child: Text('Languages')),
                    DropdownMenuItem(
                        value: 'Mathematics', child: Text('Mathematics')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => department = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: employmentType,
                  decoration: const InputDecoration(
                    labelText: 'Employment type',
                    prefixIcon: Icon(Icons.work_outline_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Full-time', child: Text('Full-time')),
                    DropdownMenuItem(
                        value: 'Part-time', child: Text('Part-time')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => employmentType = v);
                  },
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PASSPORT PHOTOGRAPH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickPassport,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEFF6FF),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 2,
                            ),
                            image: passportImage != null
                                ? DecorationImage(
                                    image: FileImage(passportImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: passportImage == null
                              ? Icon(
                                  Icons.camera_alt_rounded,
                                  size: 36,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        passportImage == null
                            ? 'Tap to upload passport photo'
                            : 'Tap to change photo',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (passportImage != null) ...[
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => passportImage = null),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove photo'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                PremiumForm.primaryButton(
                  label: isEdit ? 'UPDATE TEACHER' : 'SAVE TEACHER',
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

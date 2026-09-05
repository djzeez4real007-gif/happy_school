import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/school_posts.dart';
import '../../models/staff_member.dart';
import '../../services/staff_storage.dart';

class NonTeachingStaffFormScreen extends StatefulWidget {
  final StaffMember? staff;
  final int? index;

  const NonTeachingStaffFormScreen({super.key, this.staff, this.index});

  @override
  State<NonTeachingStaffFormScreen> createState() =>
      _NonTeachingStaffFormScreenState();
}

class _NonTeachingStaffFormScreenState
    extends State<NonTeachingStaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final otherQualCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  String gender = 'Male';
  String post = SchoolPosts.nonTeachingPosts.first;
  String qualification = 'None';
  bool active = true;
  bool saving = false;
  File? passportImage;
  final _picker = ImagePicker();

  static const qualifications = [
    'None',
    'FSLC',
    'WAEC',
    'NECO',
    'NABTEB',
    'Trade Test / Vocational',
    'Diploma',
    'ND',
    'HND',
    'NCE',
    'B.Sc / B.A / B.Ed',
    'M.Sc / M.A / M.Ed',
    'PhD',
    'Other',
  ];

  bool get isEdit => widget.staff != null;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    if (s != null) {
      nameCtrl.text = s.fullName;
      phoneCtrl.text = s.phone;
      emailCtrl.text = s.email;
      addressCtrl.text = s.address;
      otherQualCtrl.text = s.otherQualifications;
      noteCtrl.text = s.note;
      gender = s.gender.isNotEmpty ? s.gender : 'Male';
      post = SchoolPosts.nonTeachingPosts.contains(s.post)
          ? s.post
          : SchoolPosts.nonTeachingPosts.last;
      qualification = qualifications.contains(s.qualification)
          ? s.qualification
          : (s.qualification.isNotEmpty ? 'Other' : 'None');
      active = s.active;
      if (s.passport.isNotEmpty) {
        try {
          final f = File(s.passport);
          if (f.existsSync()) passportImage = f;
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    otherQualCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPassport() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => passportImage = File(image.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await StaffStorage.open();
      final passportPath = passportImage?.path ?? widget.staff?.passport ?? '';
      if (isEdit && widget.index != null) {
        final updated = widget.staff!.copyWith(
          fullName: nameCtrl.text.trim(),
          gender: gender,
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          address: addressCtrl.text.trim(),
          post: post,
          qualification: qualification,
          otherQualifications: otherQualCtrl.text.trim(),
          note: noteCtrl.text.trim(),
          passport: passportPath,
          active: active,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await StaffStorage.update(widget.index!, updated);
      } else {
        await StaffStorage.create(
          fullName: nameCtrl.text.trim(),
          post: post,
          gender: gender,
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          address: addressCtrl.text.trim(),
          note: noteCtrl.text.trim(),
          passport: passportPath,
          qualification: qualification,
          otherQualifications: otherQualCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Staff updated' : 'Staff registered'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration _dec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        leading: AppBack.leading(context),
        title: Text(isEdit ? 'Edit staff' : 'Register staff'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Non-teaching staff only (bursar, security, cleaner, chef…). '
                'They are stored separately from students and teachers — '
                'not listed under Students or Student Payments. '
                'Principal login remains under Users & Roles.',
                style: TextStyle(color: Colors.white, height: 1.4, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // Passport
            Center(
              child: Column(
                children: [
                  InkWell(
                    onTap: kIsWeb ? null : _pickPassport,
                    borderRadius: BorderRadius.circular(60),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFFCCFBF1),
                      backgroundImage: passportImage != null
                          ? FileImage(passportImage!)
                          : null,
                      child: passportImage == null
                          ? const Icon(Icons.add_a_photo_rounded,
                              size: 36, color: Color(0xFF0F766E))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kIsWeb
                        ? 'Passport photo (use mobile/desktop app to upload)'
                        : (passportImage == null
                            ? 'Tap to upload passport photo'
                            : 'Tap to change photo'),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!kIsWeb && passportImage != null)
                    TextButton.icon(
                      onPressed: () => setState(() => passportImage = null),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove photo'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: nameCtrl,
              decoration: _dec('Full name *', icon: Icons.person_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: post,
              decoration: _dec('Post *', icon: Icons.badge_outlined),
              items: SchoolPosts.nonTeachingPosts
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => post = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: gender,
              decoration: _dec('Gender', icon: Icons.wc_outlined),
              items: const ['Male', 'Female']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => gender = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: qualification,
              decoration:
                  _dec('Highest qualification', icon: Icons.school_outlined),
              items: qualifications
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => qualification = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: otherQualCtrl,
              maxLines: 2,
              decoration: _dec(
                'Other qualifications / certificates',
                icon: Icons.workspace_premium_outlined,
              ).copyWith(
                hintText: 'e.g. WAEC + Trade Test, First Aid, Driver’s licence',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec('Phone', icon: Icons.phone_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('Email', icon: Icons.email_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressCtrl,
              maxLines: 2,
              decoration: _dec('Address', icon: Icons.home_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: _dec('Note (optional)', icon: Icons.notes_outlined),
            ),
            if (isEdit) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Active'),
                value: active,
                activeColor: const Color(0xFF0F766E),
                onChanged: (v) => setState(() => active = v),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  saving
                      ? 'Saving…'
                      : (isEdit ? 'UPDATE STAFF' : 'REGISTER STAFF'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

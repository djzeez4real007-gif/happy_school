import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';

import '../../core/widgets/premium_feedback.dart';
import '../../core/widgets/premium_form.dart';
import '../../core/theme/app_colors.dart';

import '../../models/app_user.dart';
import '../../services/audit_log_storage.dart';
import '../../services/auth_service.dart';
import '../../services/user_storage.dart';

class UserFormScreen extends StatefulWidget {
  final AppUser? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final childrenController = TextEditingController();
  final teacherIdController = TextEditingController();

  String role = 'subject_teacher';
  bool isActive = true;
  bool saving = false;
  bool obscurePassword = true;
  // children for parent role

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      nameController.text = widget.user!.fullName;
      usernameController.text = widget.user!.username;
      role = widget.user!.role;
      isActive = widget.user!.isActive;
      childrenController.text = widget.user!.linkedAdmissionNos ?? '';
      teacherIdController.text = widget.user!.linkedTeacherId ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    childrenController.dispose();
    teacherIdController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      if (isEdit) {
        final existing = widget.user!;
        final newHash = passwordController.text.trim().isEmpty
            ? existing.passwordHash
            : AuthService.hashPassword(passwordController.text);

        final updated = existing.copyWith(
          fullName: nameController.text.trim(),
          username: usernameController.text.trim(),
          passwordHash: newHash,
          role: role,
          isActive: isActive,
          linkedAdmissionNos: role == 'parent'
              ? childrenController.text.trim()
              : null,
          linkedTeacherId: (role == 'class_teacher' || role == 'subject_teacher')
              ? teacherIdController.text.trim()
              : null,
        );

        await UserStorage.updateUser(existing.id, updated);

        // Keep session in sync if editing self
        if (AuthService.currentUser?.id == existing.id) {
          // re-read via login session is enough if we update current
        }
      } else {
        if (passwordController.text.trim().length < 4) {
          throw Exception('Password must be at least 4 characters');
        }

        final user = AppUser(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fullName: nameController.text.trim(),
          username: usernameController.text.trim(),
          passwordHash: AuthService.hashPassword(passwordController.text),
          role: role,
          isActive: isActive,
          linkedAdmissionNos: role == 'parent'
              ? childrenController.text.trim()
              : null,
          linkedTeacherId: (role == 'class_teacher' || role == 'subject_teacher')
              ? teacherIdController.text.trim()
              : null,
        );

        await UserStorage.addUser(user);
      }

      if (!mounted) return;
      await AuditLogStorage.log(
        action: isEdit ? 'user_updated' : 'user_created',
        module: 'users',
        description: isEdit
            ? 'Updated user ${nameController.text.trim()} ($role)'
            : 'Created user ${nameController.text.trim()} ($role)',
        refId: usernameController.text.trim(),
      );
      PremiumFeedback.success(
        context,
        title: isEdit ? 'User updated' : 'User created successfully',
        subtitle: isEdit ? 'Account changes saved' : 'New account is ready to use',
        icon: Icons.manage_accounts_rounded,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(
        context,
        title: 'Could not save user',
        subtitle: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        leading: AppBack.leading(context),
        title: Text(isEdit ? 'Edit User' : 'Add User'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter full name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter username' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: isEdit
                    ? 'New Password (leave blank to keep)'
                    : 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
              ),
              validator: (v) {
                if (!isEdit && (v == null || v.trim().length < 4)) {
                  return 'At least 4 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              items: AppUser.allRoles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(AppUser.roleLabel(r)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => role = v);
              },
            ),
            const SizedBox(height: 12),
            if (role == 'class_teacher' || role == 'subject_teacher') ...[
              TextFormField(
                controller: teacherIdController,
                decoration: const InputDecoration(
                  labelText: 'Linked Staff ID',
                  hintText: 'HST/2026/0001',
                  helperText: 'Must match teacher Staff ID for class/subject access',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (role == 'parent') ...[
              TextFormField(
                controller: childrenController,
                decoration: const InputDecoration(
                  labelText: 'Children admission numbers',
                  hintText: 'HSC/2026/0001, HSC/2026/0002',
                  helperText: 'Comma-separated for 2–3 children',
                  prefixIcon: Icon(Icons.child_care),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SwitchListTile(
              title: const Text('Account Active'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isEdit ? 'UPDATE USER' : 'CREATE USER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

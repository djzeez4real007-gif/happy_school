import 'package:flutter/material.dart';

import '../../core/permissions.dart';

import '../../core/theme/app_colors.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/user_storage.dart';
import 'user_form_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final searchController = TextEditingController();
  String query = '';

  List<AppUser> users = [];
  bool loading = true;

  
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await UserStorage.getUsers();
    data.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    if (!mounted) return;
    setState(() {
      users = data;
      loading = false;
    });
  }

  Future<void> openForm({AppUser? user}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (result == true) await loadUsers();
  }

  Future<void> confirmDelete(AppUser user) async {
    final actor = AuthService.currentUser;
    if (user.id == actor?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account')),
      );
      return;
    }
    if (actor != null &&
        !Permissions.canDeleteUser(actor.role, user.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Principal cannot delete the Administrator'),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: Text('Delete ${user.fullName} (${user.username})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await UserStorage.deleteUser(user.id);
      await loadUsers();
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFB91C1C);
      case 'principal':
        return const Color(0xFF7C3AED);
      case 'class_teacher':
        return const Color(0xFF1D4ED8);
      case 'subject_teacher':
        return const Color(0xFF0D9488);
      case 'accountant':
        return const Color(0xFFD97706);
      case 'parent':
        return const Color(0xFF059669);
      default:
        return Colors.grey.shade700;
    }
  }

  List<AppUser> get filteredUsers {
    if (query.trim().isEmpty) return users;
    final q = query.toLowerCase();
    return users
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q) ||
            AppUser.roleLabel(u.role).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Users & Roles (${users.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Add user',
            onPressed: () => openForm(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        backgroundColor: _primary,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add User'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.manage_accounts_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No users found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search name, username, role…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final color = _roleColor(user.role);
                    final initial = user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: user.isActive
                              ? Colors.grey.shade200
                              : Colors.red.shade100,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => openForm(user: user),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '@${user.username}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              AppUser.roleLabel(user.role),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                          if (!user.isActive)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEE2E2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'Disabled',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFB91C1C),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') openForm(user: user);
                                    if (value == 'delete') confirmDelete(user);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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

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
  final Set<String> _expanded = {
    'admin',
    'principal',
    'class_teacher',
    'subject_teacher',
    'accountant',
    'parent',
    'student',
    'other',
  };

  static const Color _primary = Color(0xFF1D4ED8);

  /// Display order of role folders
  static const _roleOrder = [
    'admin',
    'principal',
    'class_teacher',
    'subject_teacher',
    'accountant',
    'parent',
    'student',
  ];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);
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
    if (actor != null && !Permissions.canDeleteUser(actor.role, user.role)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the Administrator can delete users'),
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
      case 'student':
        return const Color(0xFF2563EB);
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'principal':
        return Icons.account_balance_rounded;
      case 'class_teacher':
        return Icons.class_rounded;
      case 'subject_teacher':
        return Icons.menu_book_rounded;
      case 'accountant':
        return Icons.payments_rounded;
      case 'parent':
        return Icons.family_restroom_rounded;
      case 'student':
        return Icons.school_rounded;
      default:
        return Icons.folder_rounded;
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

  Map<String, List<AppUser>> get _grouped {
    final map = <String, List<AppUser>>{};
    for (final u in filteredUsers) {
      final key = _roleOrder.contains(u.role) ? u.role : 'other';
      map.putIfAbsent(key, () => []).add(u);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final keys = [
      ..._roleOrder.where((k) => grouped.containsKey(k)),
      if (grouped.containsKey('other')) 'other',
    ];

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
                      const SizedBox(height: 8),
                      const Text(
                        'Register staff under Register, then create\n'
                        'their login here with Add User.',
                        textAlign: TextAlign.center,
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
                        decoration: InputDecoration(
                          hintText: 'Search name, username, role…',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.card(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() => query = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Staff registered under Register are not logins yet. '
                        'Use Add User and link the teacher to create a login.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: keys.length,
                        itemBuilder: (context, i) {
                          final role = keys[i];
                          final list = grouped[role] ?? [];
                          final open = _expanded.contains(role);
                          final color = _roleColor(role);
                          final label = role == 'other'
                              ? 'Other'
                              : AppUser.roleLabel(role);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.cardBorder(context),
                              ),
                            ),
                            child: Column(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      setState(() {
                                        if (open) {
                                          _expanded.remove(role);
                                        } else {
                                          _expanded.add(role);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(_roleIcon(role),
                                                color: color),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${list.length}',
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            open
                                                ? Icons.expand_less_rounded
                                                : Icons.expand_more_rounded,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (open) ...[
                                  const Divider(height: 1),
                                  if (list.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('No users in this folder'),
                                    )
                                  else
                                    ...list.map((user) {
                                      final initial = user.fullName.isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : '?';
                                      return ListTile(
                                        onTap: () => openForm(user: user),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              color.withValues(alpha: 0.15),
                                          child: Text(
                                            initial,
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          user.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                        subtitle: Text(
                                          '@${user.username}'
                                          '${user.isActive ? '' : ' · Disabled'}',
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (v) {
                                            if (v == 'edit') {
                                              openForm(user: user);
                                            } else if (v == 'delete') {
                                              confirmDelete(user);
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ],
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

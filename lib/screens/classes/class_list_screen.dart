import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../services/class_storage.dart';
import '../../services/student_class_storage.dart';
import 'class_registration_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  List classes = [];
  List _assignments = [];
  bool loading = true;

  
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    setState(() => loading = true);
    final data = await ClassStorage.getClasses();
    final assignments = await StudentClassStorage.getStudents();

    if (!mounted) return;

    setState(() {
      classes = data;
      _assignments = assignments;
      loading = false;
    });
  }

  String _normalize(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
  }

  int enrolledCount(dynamic schoolClass) {
    final full = schoolClass.fullClassName.trim().toLowerCase();
    final fullNorm = _normalize(schoolClass.fullClassName);
    final baseNorm = _normalize(schoolClass.className.toString());

    final unique = <String>{};
    for (final a in _assignments) {
      final assignedClass = a.className.trim().toLowerCase();
      final assignedNorm = _normalize(a.className);

      final matches = assignedClass == full ||
          assignedNorm == fullNorm ||
          assignedNorm == baseNorm ||
          fullNorm.startsWith(assignedNorm) ||
          assignedNorm.startsWith(baseNorm);

      if (matches) {
        unique.add(a.admissionNo.trim().toLowerCase());
      }
    }
    return unique.length;
  }

  Future<void> addClass() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClassRegistrationScreen()),
    );
    if (!mounted) return;
    await loadClasses();
  }

  Future<void> editClass(dynamic schoolClass, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ClassRegistrationScreen(schoolClass: schoolClass, index: index),
      ),
    );
    if (!mounted) return;
    if (result == true) await loadClasses();
  }

  Future<void> deleteClass(dynamic schoolClass, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Class'),
          content: Text('Delete ${schoolClass.fullClassName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;
    await ClassStorage.deleteClass(index);
    if (!mounted) return;
    await loadClasses();
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
          'Classes (${classes.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addClass,
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Class'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.class_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No classes yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final schoolClass = classes[index];
                    final count = enrolledCount(schoolClass);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
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
                          onTap: () => editClass(schoolClass, index),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFD97706),
                                        Color(0xFFFBBF24),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.class_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        schoolClass.fullClassName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        schoolClass.classTeacher.isEmpty
                                            ? 'No class teacher'
                                            : schoolClass.classTeacher,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '$count students',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1D4ED8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Active',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF15803D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await editClass(schoolClass, index);
                                    } else if (value == 'delete') {
                                      await deleteClass(schoolClass, index);
                                    }
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
    );
  }
}

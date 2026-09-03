import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
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

  late String selectedSession;
  final List<String> sessions = Sessions.list();

  Color get _primary => AppColors.primary;

  @override
  void initState() {
    super.initState();
    selectedSession = Sessions.current();
    if (!sessions.contains(selectedSession)) {
      selectedSession = sessions.isNotEmpty ? sessions.first : '2026/2027';
    }
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

  /// Count students in this class **for the selected session only**.
  /// Strict: JSS1 A and JSS1 C must not share students.
  int enrolledCount(dynamic schoolClass) {
    final full = schoolClass.fullClassName.trim().toLowerCase();
    final fullNorm = _normalize(schoolClass.fullClassName);
    final sessionNorm = selectedSession.trim().toLowerCase();

    final unique = <String>{};
    for (final a in _assignments) {
      final aSession = (a.session ?? '').toString().trim().toLowerCase();
      if (aSession != sessionNorm) continue;

      final assignedClass = a.className.trim().toLowerCase();
      final assignedNorm = _normalize(a.className);

      if (assignedClass == 'left' ||
          assignedClass == 'graduated' ||
          assignedClass == 'withdrawn') {
        continue;
      }

      // Exact class name only (including arm/section letter)
      final matches =
          assignedClass == full || assignedNorm == fullNorm;

      if (matches) {
        final adm = a.admissionNo.trim().toLowerCase();
        if (adm.isNotEmpty) unique.add(adm);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addClass,
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Class'),
      ),
      body: Column(
        children: [
          // Session filter
          Container(
            width: double.infinity,
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sessions.contains(selectedSession)
                      ? selectedSession
                      : null,
                  isExpanded: true,
                  hint: const Text('Academic session'),
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: sessions
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => selectedSession = v);
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing enrolment for $selectedSession',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : classes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.class_outlined,
                                size: 56, color: Colors.grey.shade400),
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
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final schoolClass = classes[index];
                          final count = enrolledCount(schoolClass);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => editClass(schoolClass, index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.class_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              schoolClass.fullClassName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              schoolClass.classTeacher
                                                      .toString()
                                                      .isEmpty
                                                  ? 'No class teacher'
                                                  : schoolClass.classTeacher
                                                      .toString(),
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFDBEAFE),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    '$count student${count == 1 ? '' : 's'}',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFDCFCE7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: const Text(
                                                    'Active',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                            await editClass(
                                                schoolClass, index);
                                          } else if (value == 'delete') {
                                            await deleteClass(
                                                schoolClass, index);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit')),
                                          PopupMenuItem(
                                              value: 'delete',
                                              child: Text('Delete')),
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

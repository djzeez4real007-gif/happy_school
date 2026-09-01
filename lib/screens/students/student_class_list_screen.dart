import 'package:flutter/material.dart';

import '../../models/student_class.dart';
import '../../services/student_class_storage.dart';
import '../promotion/student_promotion_screen.dart';
import 'student_class_assignment_screen.dart';

class StudentClassListScreen extends StatefulWidget {
  const StudentClassListScreen({super.key});

  @override
  State<StudentClassListScreen> createState() => _StudentClassListScreenState();
}

class _StudentClassListScreenState extends State<StudentClassListScreen> {
  List<StudentClass> students = [];
  List<StudentClass> filteredStudents = [];
  bool loading = true;

  /// Expanded folder keys: "session||className"
  final Set<String> _expanded = {};

  final TextEditingController searchController = TextEditingController();

  static const Color _bg = Color(0xFFF5F7FB);
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() => loading = true);
    final data = await StudentClassStorage.getStudents();

    if (!mounted) return;

    setState(() {
      students = data;
      filteredStudents = List<StudentClass>.from(data);
      loading = false;
    });
  }

  void searchStudent(String value) {
    final query = value.trim().toLowerCase();

    final results = query.isEmpty
        ? List<StudentClass>.from(students)
        : students.where((student) {
            return student.studentName.toLowerCase().contains(query) ||
                student.admissionNo.toLowerCase().contains(query) ||
                student.className.toLowerCase().contains(query) ||
                student.session.toLowerCase().contains(query);
          }).toList();

    if (!mounted) return;
    setState(() {
      filteredStudents = results;
      // Auto-expand matching folders when searching
      if (query.isNotEmpty) {
        for (final s in results) {
          // folders stay closed unless user opens or searches
        }
      }
    });
  }

  String _folderKey(String session, String className) =>
      '${session.trim()}||${className.trim()}';

  /// session → className → students
  Map<String, Map<String, List<StudentClass>>> get _folders {
    final map = <String, Map<String, List<StudentClass>>>{};
    for (final s in filteredStudents) {
      final session = s.session.trim().isEmpty ? 'No session' : s.session.trim();
      final cls = s.className.trim().isEmpty ? 'No class' : s.className.trim();
      map.putIfAbsent(session, () => {});
      map[session]!.putIfAbsent(cls, () => []);
      map[session]![cls]!.add(s);
    }
    // sort students by name inside each class
    for (final sess in map.keys) {
      for (final cls in map[sess]!.keys) {
        map[sess]![cls]!.sort(
          (a, b) => a.studentName.toLowerCase().compareTo(
                b.studentName.toLowerCase(),
              ),
        );
      }
    }
    return map;
  }

  Future<void> openAddAssignment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentClassAssignmentScreen()),
    );
    if (!mounted) return;
    await loadStudents();
  }

  Future<void> openPromotion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentPromotionScreen()),
    );
    if (!mounted) return;
    await loadStudents();
  }

  Future<void> editAssignment(StudentClass student, int realIndex) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentClassAssignmentScreen(
          studentClass: student,
          index: realIndex,
        ),
      ),
    );
    if (!mounted) return;
    await loadStudents();
  }

  Future<void> deleteAssignment(StudentClass student, int realIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Assignment'),
          content: Text(
            'Remove class assignment for ${student.studentName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    await StudentClassStorage.deleteStudent(realIndex);
    if (!mounted) return;
    await loadStudents();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Assignment deleted'),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folders = _folders;
    final sessions = folders.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newer sessions first

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Assigned (${filteredStudents.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Promote Students',
            icon: const Icon(Icons.upgrade_rounded),
            onPressed: openPromotion,
          ),
          IconButton(
            tooltip: 'Add Assignment',
            icon: const Icon(Icons.add_rounded),
            onPressed: openAddAssignment,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddAssignment,
        backgroundColor: _primary,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Assign'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: searchStudent,
                decoration: InputDecoration(
                  hintText: 'Search name, admission, class, session...',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredStudents.isEmpty
                    ? Center(
                        child: Text(
                          'No assigned students',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                        itemCount: sessions.length,
                        itemBuilder: (context, sIndex) {
                          final session = sessions[sIndex];
                          final classMap = folders[session]!;
                          final classNames = classMap.keys.toList()..sort();
                          final sessionCount = classMap.values
                              .fold<int>(0, (n, list) => n + list.length);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              leading: const Icon(
                                Icons.folder_rounded,
                                color: Color(0xFFD97706),
                              ),
                              title: Text(
                                session,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                '$sessionCount student(s) · ${classNames.length} class(es)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              children: classNames.map((className) {
                                final list = classMap[className]!;
                                final key = _folderKey(session, className);
                                final open = _expanded.contains(key);

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    bottom: 8,
                                  ),
                                  child: Material(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent,
                                      ),
                                      child: ExpansionTile(
                                        initiallyExpanded: open,
                                        onExpansionChanged: (v) {
                                          setState(() {
                                            if (v) {
                                              _expanded.add(key);
                                            } else {
                                              _expanded.remove(key);
                                            }
                                          });
                                        },
                                        leading: const Icon(
                                          Icons.folder_open_rounded,
                                          color: _primary,
                                          size: 22,
                                        ),
                                        title: Text(
                                          className,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${list.length} student(s)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        children: list.map((student) {
                                          final realIndex =
                                              students.indexWhere(
                                            (e) =>
                                                e.admissionNo ==
                                                    student.admissionNo &&
                                                e.session == student.session &&
                                                e.className ==
                                                    student.className,
                                          );
                                          return _studentTile(
                                            student,
                                            realIndex,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _studentTile(StudentClass student, int realIndex) {
    final initial = student.studentName.isNotEmpty
        ? student.studentName[0].toUpperCase()
        : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: _primary.withValues(alpha: 0.12),
        child: Text(
          initial,
          style: const TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        student.studentName,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        student.admissionNo,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (realIndex == -1) return;
          if (value == 'edit') {
            await editAssignment(student, realIndex);
          }
          if (value == 'promote') {
            await openPromotion();
          }
          if (value == 'delete') {
            await deleteAssignment(student, realIndex);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'promote', child: Text('Promote')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

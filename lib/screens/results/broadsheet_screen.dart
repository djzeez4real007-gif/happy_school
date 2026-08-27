import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_colors.dart';

import '../../models/school_class.dart';
import '../../models/class_subject.dart';
import '../../models/student_class.dart';
import '../../models/result.dart';

import '../../services/class_storage.dart';
import '../../services/class_subject_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/result_storage.dart';

class BroadsheetScreen extends StatefulWidget {
  const BroadsheetScreen({super.key});

  @override
  State<BroadsheetScreen> createState() => _BroadsheetScreenState();
}

class _BroadsheetScreenState extends State<BroadsheetScreen> {
  // ==========================================================
  // DATA
  // ==========================================================

  List<SchoolClass> classes = [];
  List<ClassSubject> subjects = [];
  List<StudentClass> students = [];
  List<Result> results = [];

  SchoolClass? selectedClass;

  String selectedSession = '2026/2027';
  String selectedTerm = 'First Term';

  bool loadingClasses = true;
  bool loadingBroadsheet = false;

  // ==========================================================
  // SCROLL CONTROLLERS
  // ==========================================================

  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalController = ScrollController();

  final List<String> sessions = List.generate(50, (index) {
    final startYear = 2026 + index;
    return '$startYear/${startYear + 1}';
  });

  final List<String> terms = const ['First Term', 'Second Term', 'Third Term'];

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  // ==========================================================
  // LOAD CLASSES
  // ==========================================================

  Future<void> loadClasses() async {
    try {
      List<SchoolClass> data = [];
      try {
        data = await ClassStorage.getClasses();
      } catch (_) {
        data = [];
      }

      // Fallback: class names from student assignments / subjects
      if (data.isEmpty) {
        final names = <String>{};
        try {
          final sc = await StudentClassStorage.getStudents();
          for (final s in sc) {
            final n = s.className.trim();
            if (n.isNotEmpty) names.add(n);
          }
        } catch (_) {}
        try {
          final subjects = await ClassSubjectStorage.getAssignments();
          for (final a in subjects) {
            final n = a.className.trim();
            if (n.isNotEmpty) names.add(n);
          }
        } catch (_) {}

        for (final name in names) {
          final parts = name.split(RegExp(r'\s+'));
          final base = parts.isNotEmpty ? parts.first : name;
          final arm = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          data.add(
            SchoolClass(
              className: base,
              arm: arm,
              teacherId: '',
              classTeacher: '',
              capacity: 0,
            ),
          );
        }
        data.sort(
          (a, b) => a.fullClassName.toLowerCase().compareTo(
                b.fullClassName.toLowerCase(),
              ),
        );
      }

      if (!mounted) return;

      setState(() {
        classes = data;
        loadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingClasses = false;
      });

      _showMessage('Unable to load classes.');
    }
  }

  // ==========================================================
  // LOAD BROADSHEET
  // ==========================================================

  Future<void> loadBroadsheet() async {
    if (selectedClass == null) {
      return;
    }

    setState(() {
      loadingBroadsheet = true;
      subjects = [];
      students = [];
      results = [];
    });

    try {
      final className = selectedClass!.fullClassName;

      // ------------------------------------------------------
      // SUBJECTS
      // ------------------------------------------------------

      final loadedSubjects = await ClassSubjectStorage.getClassSubjects(
        className,
      );

      loadedSubjects.sort(
        (a, b) =>
            a.subjectCode.toLowerCase().compareTo(b.subjectCode.toLowerCase()),
      );

      // ------------------------------------------------------
      // STUDENTS
      //
      // IMPORTANT:
      // Filter by:
      //
      // CLASS + SESSION + TERM
      // ------------------------------------------------------

      // Flexible match so "JSS2" (promoted) appears under "JSS2 A"
      String normClass(String v) =>
          v.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

      final selectedFull = className.trim().toLowerCase();
      final selectedNorm = normClass(className);
      final baseMatch = RegExp(r'^(jss\s*[123]|ss\s*[123])', caseSensitive: false)
          .firstMatch(className.trim());
      final selectedBaseNorm =
          baseMatch != null ? normClass(baseMatch.group(0)!) : selectedNorm;

      final allAssignments = await StudentClassStorage.getStudents();
      final assignedStudents = allAssignments.where((a) {
        if (a.session.trim() != selectedSession) return false;
        final aClass = a.className.trim().toLowerCase();
        final aNorm = normClass(a.className);
        return aClass == selectedFull ||
            aNorm == selectedNorm ||
            aNorm == selectedBaseNorm ||
            selectedNorm.startsWith(aNorm) ||
            aNorm.startsWith(selectedBaseNorm);
      }).toList();

      assignedStudents.sort(
        (a, b) =>
            a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase()),
      );

      // ------------------------------------------------------
      // RESULTS
      // ------------------------------------------------------

      final loadedResults = await ResultStorage.getClassResults(
        className: className,
        session: selectedSession,
        term: selectedTerm,
      );

      if (!mounted) return;

      setState(() {
        subjects = loadedSubjects;
        students = assignedStudents;
        results = loadedResults;
        loadingBroadsheet = false;
      });

      // Reset table scroll position whenever a new broadsheet loads.
      if (horizontalController.hasClients) {
        horizontalController.jumpTo(0);
      }

      if (verticalController.hasClients) {
        verticalController.jumpTo(0);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingBroadsheet = false;
      });

      _showMessage('Unable to load broadsheet: $e');
    }
  }

  // ==========================================================
  // GET RESULT
  // ==========================================================

  Result? getResult(StudentClass student, ClassSubject subject) {
    final admissionNo = student.admissionNo.trim().toLowerCase();

    final subjectCode = subject.subjectCode.trim().toLowerCase();

    for (final result in results) {
      final resultAdmission = result.admissionNo.trim().toLowerCase();

      final resultSubject = result.subjectCode.trim().toLowerCase();

      if (resultAdmission == admissionNo && resultSubject == subjectCode) {
        return result;
      }
    }

    return null;
  }

  // ==========================================================
  // GET STUDENT TOTAL
  // ==========================================================

  double getStudentTotal(StudentClass student) {
    double total = 0;

    for (final subject in subjects) {
      final result = getResult(student, subject);

      if (result != null) {
        total += result.total;
      }
    }

    return total;
  }

  // ==========================================================
  // GET STUDENT AVERAGE
  // ==========================================================

  double getStudentAverage(StudentClass student) {
    if (subjects.isEmpty) {
      return 0;
    }

    double total = 0;
    int resultCount = 0;

    for (final subject in subjects) {
      final result = getResult(student, subject);

      if (result != null) {
        total += result.total;
        resultCount++;
      }
    }

    if (resultCount == 0) {
      return 0;
    }

    return total / resultCount;
  }

  // ==========================================================
  // GET POSITION
  // ==========================================================

  int getStudentPosition(StudentClass student) {
    if (students.isEmpty) {
      return 0;
    }

    final studentTotals = <String, double>{};

    for (final item in students) {
      studentTotals[item.admissionNo.trim().toLowerCase()] = getStudentTotal(
        item,
      );
    }

    final sortedTotals = studentTotals.values.toList()
      ..sort((a, b) => b.compareTo(a));

    final studentTotal =
        studentTotals[student.admissionNo.trim().toLowerCase()] ?? 0;

    final index = sortedTotals.indexOf(studentTotal);

    if (index == -1) {
      return 0;
    }

    return index + 1;
  }

  // ==========================================================
  // GRADE
  // ==========================================================

  /// Display band used on broadsheet (not WAEC letter codes).
  String getGrade(double average) {
    if (average >= 70) return 'Distinction';
    if (average >= 50) return 'Credit';
    if (average >= 40) return 'Pass';
    return 'Fail';
  }

  // ==========================================================
  // GRADE COLOR
  // ==========================================================

  Color getGradeColor(double average) {
    if (average >= 75) {
      return Colors.green.shade700;
    }

    if (average >= 60) {
      return Colors.blue.shade700;
    }

    if (average >= 50) {
      return Colors.orange.shade700;
    }

    if (average >= 40) {
      return Colors.deepOrange.shade700;
    }

    return Colors.red.shade700;
  }

  // ==========================================================
  // BUILD HEADER
  // ==========================================================

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.18),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.table_chart_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Broadsheet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Class performance overview and subject scores',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FILTER CARD
  // ==========================================================

  Widget buildFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.tune_outlined, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Broadsheet Setup',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Select the academic period and class',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // SESSION
          DropdownButtonFormField<String>(
            initialValue: selectedSession,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Session',
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            items: sessions.map((session) {
              return DropdownMenuItem<String>(
                value: session,
                child: Text(session),
              );
            }).toList(),
            onChanged: (value) async {
              if (value == null) return;
              setState(() {
                selectedSession = value;
              });
              if (selectedClass != null) {
                await loadBroadsheet();
              }
            },
          ),

          const SizedBox(height: 12),

          // CLASS
          Builder(builder: (context) {
            final names = classes.map((c) => c.fullClassName).toList();
            final current = selectedClass?.fullClassName;
            final safe =
                (current != null && names.contains(current)) ? current : null;
            return DropdownButtonFormField<String>(
              key: ValueKey('bs_class_${names.length}_$safe'),
              value: safe,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Class',
                prefixIcon: const Icon(Icons.school_outlined),
                helperText: names.isEmpty
                    ? 'No classes found'
                    : '${names.length} class(es)',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              items: names
                  .map((n) => DropdownMenuItem(
                        value: n,
                        child: Text(n, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: names.isEmpty
                  ? null
                  : (value) async {
                      if (value == null) return;
                      setState(() {
                        selectedClass =
                            classes.firstWhere((c) => c.fullClassName == value);
                      });
                      await loadBroadsheet();
                    },
            );
          }),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: selectedTerm,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Term',
              prefixIcon: const Icon(Icons.event_note_outlined),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            items: terms.map((term) {
              return DropdownMenuItem<String>(
                value: term,
                child: Text(term, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) async {
              if (value == null) return;
              setState(() {
                selectedTerm = value;
              });
              if (selectedClass != null) {
                await loadBroadsheet();
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SUMMARY
  // ==========================================================

  Widget buildSummary() {
    final resultCount = results.length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.people_outline,
            label: 'Students',
            value: students.length.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.menu_book_outlined,
            label: 'Subjects',
            value: subjects.length.toString(),
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Results',
            value: resultCount.toString(),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: color.shade700),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: color.shade700,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TABLE
  // ==========================================================

  Widget buildTable() {
    if (selectedClass == null) {
      return buildEmptyState(
        Icons.school_outlined,
        'Select a class',
        'Choose a class above to view its broadsheet.',
      );
    }

    if (loadingBroadsheet) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (students.isEmpty) {
      return buildEmptyState(
        Icons.people_outline,
        'No students found',
        'There are no students assigned to '
            '${selectedClass!.fullClassName} '
            'for $selectedTerm, $selectedSession.',
      );
    }

    if (subjects.isEmpty) {
      return buildEmptyState(
        Icons.menu_book_outlined,
        'No subjects assigned',
        'No subjects have been assigned to '
            '${selectedClass!.fullClassName}.',
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_chart_outlined,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Performance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${selectedClass!.fullClassName} • '
                          '$selectedTerm • '
                          '$selectedSession',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ------------------------------------------------
            // TABLE
            //
            // IMPORTANT:
            // The horizontal Scrollbar now uses
            // horizontalController.
            //
            // The vertical Scrollbar now uses
            // verticalController.
            // ------------------------------------------------
            Scrollbar(
                controller: horizontalController,
                thumbVisibility: true,
                notificationPredicate: (notification) {
                  return notification.depth == 0;
                },
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: Scrollbar(
                    controller: verticalController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) {
                      return notification.depth == 0;
                    },
                    child: SingleChildScrollView(
                      controller: verticalController,
                      scrollDirection: Axis.vertical,
                      primary: false,
                      child: DataTable(
                        headingRowHeight: 52,
                        dataRowMinHeight: 62,
                        dataRowMaxHeight: 70,
                        columnSpacing: 22,
                        horizontalMargin: 18,
                        dividerThickness: 0.5,

                        columns: [
                          const DataColumn(
                            label: Text(
                              'STUDENT',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),

                          const DataColumn(
                            label: Text(
                              'ADMISSION NO.',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),

                          ...subjects.map(
                            (subject) => DataColumn(
                              label: SizedBox(
                                width: 72,
                                child: Text(
                                  subject.subjectCode,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const DataColumn(
                            label: Text(
                              'TOTAL',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),

                          const DataColumn(
                            label: Text(
                              'AVERAGE',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),

                          const DataColumn(
                            label: Text(
                              'GRADE',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),

                          const DataColumn(
                            label: Text(
                              'POSITION',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],

                        rows: students.map((student) {
                          final total = getStudentTotal(student);

                          final average = getStudentAverage(student);

                          final grade = getGrade(average);

                          final position = getStudentPosition(student);

                          final gradeColor = getGradeColor(average);

                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 160,
                                  child: Text(
                                    student.studentName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),

                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    student.admissionNo,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),

                              ...subjects.map((subject) {
                                final result = getResult(student, subject);

                                if (result == null) {
                                  return const DataCell(
                                    Center(
                                      child: Text(
                                        '-',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  );
                                }

                                return DataCell(
                                  Center(
                                    child: Container(
                                      width: 54,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: result.isPassed
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        result.total.toStringAsFixed(0),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: result.isPassed
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              DataCell(
                                Text(
                                  total.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),

                              DataCell(
                                Text(
                                  average.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: gradeColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    grade,
                                    style: TextStyle(
                                      color: gradeColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),

                              DataCell(
                                Text(
                                  position == 0 ? '-' : _positionText(position),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // POSITION TEXT
  // ==========================================================

  String _positionText(int position) {
    if (position % 100 >= 11 && position % 100 <= 13) {
      return '${position}th';
    }

    switch (position % 10) {
      case 1:
        return '${position}st';

      case 2:
        return '${position}nd';

      case 3:
        return '${position}rd';

      default:
        return '${position}th';
    }
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget buildEmptyState(IconData icon, String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 55),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),

      // AppBar provided by AppShell — avoids double title
      body: loadingClasses
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildHeader(),
                          const SizedBox(height: 12),
                          buildFilterCard(),
                          if (selectedClass != null) ...[
                            const SizedBox(height: 10),
                            buildSummary(),
                            const SizedBox(height: 12),
                          ],
                          buildTable(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();

    super.dispose();
  }
}
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../models/result.dart';
import '../../models/school_class.dart';
import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../models/subject.dart';

import '../../services/class_storage.dart';
import '../../services/auth_service.dart';
import '../../services/result_storage.dart';
import '../../services/audit_log_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_status_service.dart';
import '../../services/student_storage.dart';
import '../../services/subject_storage.dart';
import '../../services/class_subject_storage.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../models/class_subject.dart';
import '../../services/subject_teacher_service.dart';

class ResultEntryScreen extends StatefulWidget {
  const ResultEntryScreen({super.key});

  @override
  State<ResultEntryScreen> createState() => _ResultEntryScreenState();
}

class _ResultEntryScreenState extends State<ResultEntryScreen> {
  List<SchoolClass> classes = [];
  List<Student> students = [];
  List<Subject> subjects = [];

  SchoolClass? selectedClass;
  Subject? selectedSubject;

  String selectedSession = "2026/2027";
  String selectedTerm = "First Term";

  bool loadingClasses = true;
  bool loadingSubjects = false;
  bool loadingStudents = false;
  bool saving = false;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";

  final List<String> sessions = List.generate(50, (index) {
    final startYear = 2026 + index;
    return "$startYear/${startYear + 1}";
  });

  final List<String> terms = ["First Term", "Second Term", "Third Term"];

  final Map<String, TextEditingController> ca1Controllers = {};
  final Map<String, TextEditingController> ca2Controllers = {};
  final Map<String, TextEditingController> examControllers = {};

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        searchQuery = searchController.text.trim().toLowerCase();
      });
    });

    loadClasses();
  }

  // ==========================================================
  // LOAD CLASSES
  // ==========================================================

  Future<void> loadClasses() async {
    try {
      final data = await ClassStorage.getClasses();

      if (!mounted) return;

      // Class / subject teachers only see relevant class(es)
      final user = AuthService.currentUser;
      var filtered = List<SchoolClass>.from(data);
      if (user != null &&
          user.role == 'class_teacher' &&
          (user.linkedTeacherId ?? '').isNotEmpty) {
        final lid = user.linkedTeacherId!.trim().toLowerCase();
        filtered = filtered.where((c) {
          final tid = c.teacherId.trim().toLowerCase();
          return tid == lid || tid.contains(lid) || lid.contains(tid);
        }).toList();
      }
      // Subject teachers can pick any class; subjects are restricted below.


      filtered.sort(
        (a, b) => a.fullClassName.toLowerCase().compareTo(
          b.fullClassName.toLowerCase(),
        ),
      );

      setState(() {
        classes = filtered;
        loadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingClasses = false;
      });

      showMessage("Unable to load classes: $e");
    }
  }

  // ==========================================================
  // LOAD SUBJECTS
  // ==========================================================

  Future<void> loadSubjects() async {
    if (selectedClass == null) return;

    setState(() {
      loadingSubjects = true;
      subjects = [];
      selectedSubject = null;
      students = [];
      searchController.clear();
    });

    try {
      final fullClassName = selectedClass!.fullClassName.trim();
      final baseClassName = _getBaseClassName(fullClassName);

      // 1. Try subjects assigned specifically to this class (ClassSubjectStorage)
      final classAssignments =
          await ClassSubjectStorage.getClassSubjects(fullClassName);

      // Also try base class name e.g. "JSS2" when class is "JSS2 A"
      List<ClassSubject> baseAssignments = [];
      if (baseClassName.toLowerCase() != fullClassName.toLowerCase()) {
        baseAssignments =
            await ClassSubjectStorage.getClassSubjects(baseClassName);
      }

      final Map<String, Subject> subjectMap = {};

      // From class-subject assignments
      for (final assignment in [...classAssignments, ...baseAssignments]) {
        final code = assignment.subjectCode.trim().toLowerCase();
        if (code.isEmpty) continue;
        subjectMap[code] = Subject(
          subjectName: assignment.subjectName,
          subjectCode: assignment.subjectCode,
          studentClass: assignment.className,
        );
      }

      // 2. Also include subjects from SubjectStorage that match this class/level
      final allSubjects = await SubjectStorage.getSubjects();
      final fullLower = fullClassName.toLowerCase();
      final baseLower = baseClassName.toLowerCase();

      for (final subject in allSubjects) {
        final subjectClass = subject.studentClass.trim().toLowerCase();
        final normalizedSubjectClass =
            subjectClass.replaceAll(RegExp(r'[\s\-_]+'), '');
        final normalizedFull =
            fullLower.replaceAll(RegExp(r'[\s\-_]+'), '');
        final normalizedBase =
            baseLower.replaceAll(RegExp(r'[\s\-_]+'), '');

        final matches = subjectClass == fullLower ||
            subjectClass == baseLower ||
            normalizedSubjectClass == normalizedFull ||
            normalizedSubjectClass == normalizedBase ||
            normalizedSubjectClass.startsWith(normalizedBase);

        if (matches) {
          final code = subject.subjectCode.trim().toLowerCase();
          if (code.isNotEmpty) {
            subjectMap.putIfAbsent(code, () => subject);
          }
        }
      }

      final loadedSubjects = subjectMap.values.toList();
      loadedSubjects.sort(
        (a, b) =>
            a.subjectName.toLowerCase().compareTo(b.subjectName.toLowerCase()),
      );

      if (!mounted) return;

      var subs = loadedSubjects;
      final u = AuthService.currentUser;
      if (u != null && u.role == 'subject_teacher') {
        try {
          // Subject teacher: show ALL subjects assigned to them
          // (not only those linked on the class curriculum list)
          final myList = await SubjectTeacherService.mySubjects();
          final map = <String, Subject>{};
          for (final a in myList) {
            final code = a.subjectCode.trim().toLowerCase();
            if (code.isEmpty) continue;
            map[code] = Subject(
              subjectName: a.subjectName,
              subjectCode: a.subjectCode,
              studentClass: '',
            );
          }
          // Prefer names from global subject list when available
          final allSubjects = await SubjectStorage.getSubjects();
          for (final s in allSubjects) {
            final code = s.subjectCode.trim().toLowerCase();
            if (map.containsKey(code)) {
              map[code] = s;
            }
          }
          subs = map.values.toList();
          subs.sort(
            (a, b) => a.subjectName
                .toLowerCase()
                .compareTo(b.subjectName.toLowerCase()),
          );
        } catch (_) {
          // fall back to filtered class list
          try {
            final myCodes = await SubjectTeacherService.mySubjectCodes();
            subs = loadedSubjects
                .where(
                  (s) => myCodes.contains(s.subjectCode.trim().toLowerCase()),
                )
                .toList();
          } catch (_) {
            subs = [];
          }
        }
      }

      if (!mounted) return;

      setState(() {
        subjects = subs;
        loadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingSubjects = false;
      });

      showMessage("Unable to load subjects: $e");
    }
  }

  String _getBaseClassName(String className) {
    // "JSS2 A" -> "JSS2", "SS1 B" -> "SS1", "JSS1A" -> "JSS1"
    final cleaned = className.trim().toUpperCase();
    final match = RegExp(r'^(JSS\s*[123]|SS\s*[123])').firstMatch(cleaned);
    if (match != null) {
      return match.group(0)!.replaceAll(RegExp(r'\s+'), '');
    }
    final parts = className.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? className : parts.first;
  }

  // ==========================================================
  // LOAD STUDENTS
  // ==========================================================

  Future<void> loadStudents() async {
    if (selectedClass == null || selectedSubject == null) {
      return;
    }

    setState(() {
      loadingStudents = true;
      students = [];
      searchController.clear();
    });

    try {
      /*
       * IMPORTANT:
       *
       * StudentClassStorage currently expects:
       *
       * getStudentsByClass({
       *   required String className,
       *   required String session,
       *   required String term,
       * })
       *
       * Therefore we MUST use named arguments here.
       */

      // Load all assignments for the session, then match flexibly.
      // This includes students promoted as "JSS2" when class is "JSS2 A".
      final allAssignments = await StudentClassStorage.getStudents();
      final selectedFull = selectedClass!.fullClassName.trim().toLowerCase();
      final selectedBase = _getBaseClassName(selectedClass!.fullClassName)
          .trim()
          .toLowerCase();

      String norm(String v) =>
          v.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

      final selectedNorm = norm(selectedClass!.fullClassName);
      final selectedBaseNorm = norm(selectedBase);

      // Strict match: JSS1 A must not include JSS1 B
      final assignedStudents = allAssignments.where((a) {
        if (a.session.trim() != selectedSession) return false;
        if (StudentStatusService.isInactiveClassName(a.className)) return false;

        final aClass = a.className.trim().toLowerCase();
        final aNorm = norm(a.className);

        return aClass == selectedFull || aNorm == selectedNorm;
      }).toList();

      final allStudents = await StudentStorage.getStudents();

      final Map<String, Student> studentMap = {};

      for (final student in allStudents) {
        studentMap[student.admissionNo.trim().toLowerCase()] = student;
      }

      final List<Student> loadedStudents = [];
      final seen = <String>{};

      for (final StudentClass assignment in assignedStudents) {
        final key = assignment.admissionNo.trim().toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);

        final student = studentMap[key];

        if (student != null) {
          loadedStudents.add(student);
        }
      }

      loadedStudents.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

      for (final student in loadedStudents) {
        _createControllers(student.admissionNo);
      }

      if (!mounted) return;

      setState(() {
        students = loadedStudents;
        loadingStudents = false;
      });

      await loadExistingResults();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingStudents = false;
      });

      showMessage("Unable to load students: $e");
    }
  }

  // ==========================================================
  // CREATE SCORE CONTROLLERS
  // ==========================================================

  void _createControllers(String admissionNo) {
    ca1Controllers.putIfAbsent(admissionNo, () => TextEditingController());

    ca2Controllers.putIfAbsent(admissionNo, () => TextEditingController());

    examControllers.putIfAbsent(admissionNo, () => TextEditingController());
  }

  // ==========================================================
  // LOAD EXISTING RESULTS
  // ==========================================================

  Future<void> loadExistingResults() async {
    if (selectedSubject == null || students.isEmpty) {
      return;
    }

    for (final student in students) {
      final existing = await ResultStorage.getStudentResult(
        admissionNo: student.admissionNo,
        subjectCode: selectedSubject!.subjectCode,
        session: selectedSession,
        term: selectedTerm,
      );

      final ca1Controller = ca1Controllers[student.admissionNo]!;

      final ca2Controller = ca2Controllers[student.admissionNo]!;

      final examController = examControllers[student.admissionNo]!;

      if (existing == null) {
        ca1Controller.clear();
        ca2Controller.clear();
        examController.clear();
      } else {
        ca1Controller.text = _formatScore(existing.ca1);
        ca2Controller.text = _formatScore(existing.ca2);
        examController.text = _formatScore(existing.exam);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _formatScore(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  // ==========================================================
  // FILTER STUDENTS
  // ==========================================================

  List<Student> get filteredStudents {
    if (searchQuery.isEmpty) {
      return students;
    }

    return students.where((student) {
      final name = student.fullName.toLowerCase();
      final admissionNo = student.admissionNo.toLowerCase();

      return name.contains(searchQuery) || admissionNo.contains(searchQuery);
    }).toList();
  }

  // ==========================================================
  // SAVE RESULTS
  // ==========================================================

  Future<void> saveResults() async {
    if (selectedClass == null) {
      showMessage('Please select a class first.');
      return;
    }
    if (selectedSubject == null) {
      showMessage('Please select a subject first.');
      return;
    }
    if (students.isEmpty) {
      showMessage('No students loaded for this class.');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      int saved = 0;
      for (final student in students) {
        final ca1Ctrl = ca1Controllers[student.admissionNo];
        final ca2Ctrl = ca2Controllers[student.admissionNo];
        final examCtrl = examControllers[student.admissionNo];
        if (ca1Ctrl == null || ca2Ctrl == null || examCtrl == null) {
          continue;
        }

        final ca1 = double.tryParse(ca1Ctrl.text.trim()) ?? 0;
        final ca2 = double.tryParse(ca2Ctrl.text.trim()) ?? 0;
        final exam = double.tryParse(examCtrl.text.trim()) ?? 0;

        if (ca1 < 0 || ca1 > 20) {
          showMessage('CA1 for ${student.fullName} must be between 0 and 20.');
          return;
        }
        if (ca2 < 0 || ca2 > 20) {
          showMessage('CA2 for ${student.fullName} must be between 0 and 20.');
          return;
        }
        if (exam < 0 || exam > 60) {
          showMessage('Exam for ${student.fullName} must be between 0 and 60.');
          return;
        }

        final result = Result(
          admissionNo: student.admissionNo,
          studentName: student.fullName,
          className: selectedClass!.fullClassName,
          subjectCode: selectedSubject!.subjectCode,
          subjectName: selectedSubject!.subjectName,
          session: selectedSession,
          term: selectedTerm,
          ca1: ca1,
          ca2: ca2,
          exam: exam,
        );

        await ResultStorage.saveResult(result);
        // Verify write
        final check = await ResultStorage.getStudentResult(
          admissionNo: student.admissionNo,
          subjectCode: selectedSubject!.subjectCode,
          session: selectedSession,
          term: selectedTerm,
        );
        if (check == null) {
          throw Exception(
            'Save did not stick for ${student.fullName}. Check results storage.',
          );
        }
        saved++;
      }

      try {
        await AuditLogStorage.log(
          action: 'result_saved',
          module: 'results',
          description:
              'Saved results for ${selectedSubject!.subjectName} · ${selectedClass!.fullClassName} · $selectedTerm · $selectedSession ($saved students)',
          refId: selectedClass!.fullClassName,
        );
      } catch (_) {}

      if (!mounted) return;

      final totalInBox = (await ResultStorage.getResults()).length;
      try {
        PremiumFeedback.success(
          context,
          title: 'Results saved',
          subtitle:
              '$saved student score(s) stored for ${selectedSubject!.subjectName}',
        );
      } catch (_) {}
      showMessage(
        'Saved $saved result(s) for ${selectedSubject!.subjectName}. Box total: $totalInBox',
      );
    } catch (e) {
      if (!mounted) return;
      showMessage('Could not save results: $e');
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // ==========================================================
  // CLEAR RESULTS
  // ==========================================================

  void clearResults() {
    for (final controller in ca1Controllers.values) {
      controller.clear();
    }

    for (final controller in ca2Controllers.values) {
      controller.clear();
    }

    for (final controller in examControllers.values) {
      controller.clear();
    }

    setState(() {});
  }

  // ==========================================================
  // TOTAL
  // ==========================================================

  double getStudentTotal(Student student) {
    final ca1 =
        double.tryParse(ca1Controllers[student.admissionNo]?.text ?? "") ?? 0;

    final ca2 =
        double.tryParse(ca2Controllers[student.admissionNo]?.text ?? "") ?? 0;

    final exam =
        double.tryParse(examControllers[student.admissionNo]?.text ?? "") ?? 0;

    return ca1 + ca2 + exam;
  }

  // ==========================================================
  // GRADE
  // ==========================================================

  String getGrade(double total) {
    if (total >= 75) return "A1";
    if (total >= 70) return "B2";
    if (total >= 65) return "B3";
    if (total >= 60) return "C4";
    if (total >= 55) return "C5";
    if (total >= 50) return "C6";
    if (total >= 45) return "D7";
    if (total >= 40) return "E8";
    return "F9";
  }

  String getRemark(double total) {
    if (total >= 75) return "Excellent";
    if (total >= 60) return "Very Good";
    if (total >= 50) return "Credit";
    if (total >= 40) return "Pass";
    return "Fail";
  }

  // ==========================================================
  // SCORE FIELD
  // ==========================================================

  Widget scoreField({
    required String label,
    required TextEditingController controller,
    required Color color,
    required double maxScore,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) {
          if (mounted) {
            setState(() {});
          }
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: "0-${maxScore.toInt()}",
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: Icon(Icons.edit_outlined, color: color, size: 19),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STUDENT CARD
  // ==========================================================

  Widget buildStudentCard(Student student) {
    final total = getStudentTotal(student);
    final grade = getGrade(total);
    final remark = getRemark(total);
    final passed = total >= 40;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.person_outline, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.admissionNo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: passed ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      total.toStringAsFixed(0),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: passed
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    Text(
                      grade,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: passed
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 16,
                color: passed ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                remark,
                style: TextStyle(
                  color: passed ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                "Total / 100",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              scoreField(
                label: "CA1",
                controller: ca1Controllers[student.admissionNo]!,
                color: Colors.blue,
                maxScore: 20,
              ),
              const SizedBox(width: 10),
              scoreField(
                label: "CA2",
                controller: ca2Controllers[student.admissionNo]!,
                color: Colors.orange,
                maxScore: 20,
              ),
              const SizedBox(width: 10),
              scoreField(
                label: "Exam",
                controller: examControllers[student.admissionNo]!,
                color: Colors.purple,
                maxScore: 60,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
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
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter Results",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Record and manage student academic performance",
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
  // SETUP CARD
  // ==========================================================

  Widget buildSetupCard() {
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
                child: Icon(Icons.tune, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Assessment Setup",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Choose the class, subject and academic period",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;

              if (isNarrow) {
                return Column(
                  children: [
                    buildSessionDropdown(),
                    const SizedBox(height: 12),
                    buildClassDropdown(),
                    const SizedBox(height: 12),
                    buildTermDropdown(),
                    const SizedBox(height: 12),
                    buildSubjectDropdown(),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: buildSessionDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: buildClassDropdown()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: buildTermDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: buildSubjectDropdown()),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildClassDropdown() {
    final names = classes.map((c) => c.fullClassName).toList();
    final current = selectedClass?.fullClassName;
    final safeValue =
        (current != null && names.contains(current)) ? current : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('class_dd_${names.length}_$safeValue'),
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Class",
        prefixIcon: const Icon(Icons.school_outlined),
        helperText: names.isEmpty
            ? "No classes found — register classes first"
            : "${names.length} class(es)",
      ),
      items: names
          .map(
            (name) => DropdownMenuItem<String>(
              value: name,
              child: Text(name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onTap: () {
        loadClasses();
      },
      onChanged: names.isEmpty
          ? null
          : (value) async {
              if (value == null) return;
              final schoolClass = classes.firstWhere(
                (c) => c.fullClassName == value,
              );
              setState(() {
                selectedClass = schoolClass;
                subjects = [];
                selectedSubject = null;
                students = [];
                searchController.clear();
              });
              await loadSubjects();
            },
    );
  }

  Widget buildSubjectDropdown() {
    final codes = subjects.map((s) => s.subjectCode).toList();
    final current = selectedSubject?.subjectCode;
    final safeValue =
        (current != null && codes.contains(current)) ? current : null;

    return DropdownButtonFormField<String>(
      key: ValueKey('subj_dd_${codes.length}_$safeValue'),
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Subject",
        prefixIcon: const Icon(Icons.menu_book_outlined),
        helperText: selectedClass == null
            ? "Select a class first"
            : (loadingSubjects
                ? "Loading subjects…"
                : (subjects.isEmpty
                    ? "No subjects for this class — use Assign Subjects"
                    : "${subjects.length} subject(s)")),
      ),
      items: subjects
          .map(
            (subject) => DropdownMenuItem<String>(
              value: subject.subjectCode,
              child: Text(
                "${subject.subjectName} (${subject.subjectCode})",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: loadingSubjects || subjects.isEmpty
          ? null
          : (code) async {
              if (code == null) return;
              final subject = subjects.firstWhere((s) => s.subjectCode == code);
              setState(() {
                selectedSubject = subject;
                students = [];
                searchController.clear();
              });
              await loadStudents();
            },
    );
  }

  Widget buildSessionDropdown() {
    return DropdownButtonFormField<String>(
      value: sessions.contains(selectedSession) ? selectedSession : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: "Academic Session",
        prefixIcon: Icon(Icons.calendar_month_outlined),
      ),
      items: sessions.map((session) {
        return DropdownMenuItem<String>(value: session, child: Text(session));
      }).toList(),
      onChanged: (value) async {
        if (value == null) return;

        setState(() {
          selectedSession = value;
          students = [];
        });

        if (selectedSubject != null) {
          await loadStudents();
        }
      },
    );
  }

  Widget buildTermDropdown() {
    return DropdownButtonFormField<String>(
      value: terms.contains(selectedTerm) ? selectedTerm : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: "Term",
        prefixIcon: Icon(Icons.event_note_outlined),
      ),
      items: terms.map((term) {
        return DropdownMenuItem<String>(value: term, child: Text(term));
      }).toList(),
      onChanged: (value) async {
        if (value == null) return;

        setState(() {
          selectedTerm = value;
          students = [];
        });

        if (selectedSubject != null) {
          await loadStudents();
        }
      },
    );
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Widget buildSearchBox() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        labelText: "Search students",
        hintText: "Search by name or admission number",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  searchController.clear();
                },
                icon: const Icon(Icons.clear),
              ),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
    );
  }

  // ==========================================================
  // STUDENT SECTION
  // ==========================================================

  Widget buildStudentSection() {
    final visibleStudents = filteredStudents;

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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people_outline, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Student Results",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      students.isEmpty
                          ? "No students loaded"
                          : "${students.length} students",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (students.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${students.length}",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          if (students.isNotEmpty) ...[
            buildSearchBox(),
            const SizedBox(height: 14),
          ],

          if (loadingStudents)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (students.isEmpty)
            buildEmptyStudentsState()
          else if (visibleStudents.isEmpty)
            buildNoSearchResults()
          else
            Column(children: visibleStudents.map(buildStudentCard).toList()),
        ],
      ),
    );
  }

  Widget buildEmptyStudentsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 34,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "No students available",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            selectedClass == null
                ? "Select a class first."
                : "There are no students assigned to "
                      "${selectedClass!.fullClassName} "
                      "for $selectedTerm, $selectedSession.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget buildNoSearchResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text(
            "No matching student",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            "Try another name or admission number.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SAVE BUTTON
  // ==========================================================

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: students.isEmpty || saving ? null : saveResults,
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(
          saving ? "Saving..." : "Save All Results",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void showMessage(String message) {
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

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          "Result Entry",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (students.isNotEmpty)
            IconButton(
              tooltip: "Clear scores",
              onPressed: clearResults,
              icon: const Icon(Icons.clear_all_rounded),
            ),
          if (students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: TextButton.icon(
                onPressed: saving ? null : saveResults,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(saving ? "Saving..." : "Save"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
        ],
      ),

      body: loadingClasses
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildHeader(),

                            const SizedBox(height: 18),

                            buildSetupCard(),

                            const SizedBox(height: 12),

                            if (selectedSubject != null &&
                                selectedClass != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "${selectedSubject!.subjectName} • "
                                        "${selectedClass!.fullClassName} • "
                                        "$selectedTerm • "
                                        "$selectedSession",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Save button at TOP so admin can save without scrolling
                            if (selectedClass != null &&
                                selectedSubject != null &&
                                students.isNotEmpty) ...[
                              buildSaveButton(),
                              const SizedBox(height: 12),
                            ],

                            if (selectedClass != null &&
                                selectedSubject != null)
                              buildStudentSection()
                            else
                              buildReadyState(),

                            const SizedBox(height: 12),

                            // Save button at BOTTOM as well
                            if (selectedClass != null &&
                                selectedSubject != null &&
                                students.isNotEmpty)
                              buildSaveButton(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget buildReadyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            "Ready for result entry",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            "Select a class and subject to load students.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    searchController.dispose();

    for (final controller in ca1Controllers.values) {
      controller.dispose();
    }

    for (final controller in ca2Controllers.values) {
      controller.dispose();
    }

    for (final controller in examControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }
}
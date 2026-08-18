import 'package:flutter/material.dart';

import '../../core/utils/sessions.dart';

import '../../services/audit_log_storage.dart';
import '../../core/theme/app_colors.dart';

import '../../models/student_class.dart';
import '../../models/school_class.dart';

import '../../services/student_class_storage.dart';
import '../../services/class_storage.dart';
import '../../services/student_promotion_service.dart';

class StudentPromotionScreen extends StatefulWidget {
  const StudentPromotionScreen({super.key});

  @override
  State<StudentPromotionScreen> createState() => _StudentPromotionScreenState();
}

class _PromotionPath {
  final String label;
  final String sourceClass;
  final String? targetClass;
  final bool graduated;

  const _PromotionPath({
    required this.label,
    required this.sourceClass,
    required this.targetClass,
    this.graduated = false,
  });
}

class _StudentPromotionScreenState extends State<StudentPromotionScreen> {
  // ============================================================
  // SESSION SETTINGS
  // ============================================================

  String currentSession = '2026/2027';
  String currentTerm = 'Third Term';
  String nextSession = '2027/2028';

  static const Color primaryBlue = Color(0xFF2563EB);

  final List<String> sessions = Sessions.list();


  final List<String> terms = const [
    'First Term',
    'Second Term',
    'Third Term',
  ];

  // ============================================================
  // PROMOTION PATHS
  // ============================================================

  static const List<_PromotionPath> promotionPaths = [
    _PromotionPath(
      label: 'JSS1 → JSS2',
      sourceClass: 'JSS1',
      targetClass: 'JSS2',
    ),
    _PromotionPath(
      label: 'JSS2 → JSS3',
      sourceClass: 'JSS2',
      targetClass: 'JSS3',
    ),
    _PromotionPath(
      label: 'JSS3 → SS1',
      sourceClass: 'JSS3',
      targetClass: 'SS1',
    ),
    _PromotionPath(label: 'SS1 → SS2', sourceClass: 'SS1', targetClass: 'SS2'),
    _PromotionPath(label: 'SS2 → SS3', sourceClass: 'SS2', targetClass: 'SS3'),
    _PromotionPath(
      label: 'SS3 → Graduated',
      sourceClass: 'SS3',
      targetClass: 'Graduated',
      graduated: true,
    ),
  ];

  // ============================================================
  // DATA
  // ============================================================

  List<StudentClass> allSessionStudents = [];
  List<StudentClass> filteredStudents = [];

  List<SchoolClass> classes = [];

  final TextEditingController searchController = TextEditingController();

  late _PromotionPath selectedPath;

  bool loading = true;
  bool promoting = false;

  // true = automatic
  // false = manual
  bool automaticMode = true;

  final Map<String, double> averages = {};

  final Set<String> selectedAdmissions = {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    selectedPath = promotionPaths.first;

    loadData();
  }

  // ============================================================
  // NORMALIZE CLASS NAME
  // ============================================================

  String normalizeClassName(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_]+'), '');
  }

  /// Build target class name while keeping the arm (A, B, C...).
  /// Example: current "JSS1 A" + target base "JSS2" -> "JSS2 A"
  String buildTargetClassName(String currentClassName, String targetBase) {
    if (targetBase.trim().toLowerCase() == 'graduated') {
      return 'Graduated';
    }

    final current = currentClassName.trim();

    // Strip the level part (JSS1, JSS 1, SS2, etc.) to get the arm
    final arm = current
        .replaceFirst(
          RegExp(r'^(JSS|SS)\s*[123]\s*', caseSensitive: false),
          '',
        )
        .trim();

    if (arm.isEmpty) {
      return targetBase.trim();
    }

    return '${targetBase.trim()} $arm';
  }

  // ============================================================
  // COMPUTE NEXT SESSION
  // ============================================================

  String _computeNextSession(String session) {
    // Expects format like 2026/2027
    try {
      final parts = session.split('/');
      if (parts.length == 2) {
        final start = int.parse(parts[0].trim());
        final end = int.parse(parts[1].trim());
        return '${start + 1}/${end + 1}';
      }
    } catch (_) {}
    return session;
  }

  void _onSessionChanged(String? value) {
    if (value == null) return;
    setState(() {
      currentSession = value;
      nextSession = _computeNextSession(value);
    });
    loadData();
  }

  void _onTermChanged(String? value) {
    if (value == null) return;
    setState(() {
      currentTerm = value;
    });
    loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      /*
       * IMPORTANT:
       *
       * We deliberately use getStudents() here instead of
       * getStudentsBySessionTerm().
       *
       * StudentClassAssignmentScreen currently stores the class
       * assignment with:
       *
       *     term: "First Term"
       *
       * while promotion uses:
       *
       *     currentTerm = "Third Term"
       *
       * Therefore filtering the StudentClass records by Third Term
       * makes students disappear even though their Third Term
       * RESULTS exist.
       *
       * We only need the student's current class assignment here.
       * The average is separately calculated from Third Term results.
       */

      final storedStudents = await StudentClassStorage.getStudents();

      final schoolClasses = await ClassStorage.getClasses();

      // ----------------------------------------------------------
      // Keep only students belonging to the current session.
      // ----------------------------------------------------------

      final sessionStudents = storedStudents.where((student) {
        return student.session.trim() == currentSession;
      }).toList();

      // ----------------------------------------------------------
      // Remove duplicate assignment records for the same student.
      //
      // If more than one record exists, keep the latest occurrence.
      // ----------------------------------------------------------

      final Map<String, StudentClass> uniqueStudents = {};

      for (final student in sessionStudents) {
        uniqueStudents[student.admissionNo] = student;
      }

      final students = uniqueStudents.values.toList();

      // ----------------------------------------------------------
      // Load Third Term averages.
      // ----------------------------------------------------------

      averages.clear();

      for (final student in students) {
        final average = await StudentPromotionService.getStudentAverage(
          admissionNo: student.admissionNo,
          session: currentSession,
          term: currentTerm,
        );

        averages[student.admissionNo] = average;
      }

      if (!mounted) return;

      setState(() {
        allSessionStudents = students;
        classes = schoolClasses;
        loading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage('Unable to load promotion data: $e', Colors.red.shade700);
    }
  }

  // ============================================================
  // APPLY CLASS + SEARCH FILTER
  // ============================================================

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    final sourceClass = normalizeClassName(selectedPath.sourceClass);

    final results = allSessionStudents.where((student) {
      // --------------------------------------------------------
      // CLASS FILTER
      // --------------------------------------------------------

      final studentClass = normalizeClassName(student.className);

      // Matches JSS1, JSS1A, JSS1 B, JSS 1A, SS1 A, etc.
      final matchesClass = studentClass == sourceClass ||
          studentClass.startsWith(sourceClass);

      if (!matchesClass) {
        return false;
      }

      // --------------------------------------------------------
      // SEARCH FILTER
      // --------------------------------------------------------

      if (query.isEmpty) {
        return true;
      }

      return student.studentName.toLowerCase().contains(query) ||
          student.admissionNo.toLowerCase().contains(query) ||
          student.className.toLowerCase().contains(query);
    }).toList();

    if (!mounted) return;

    setState(() {
      filteredStudents = results;

      // Remove selections that no longer belong to the
      // currently displayed promotion path.
      final visibleAdmissions = results
          .map((student) => student.admissionNo)
          .toSet();

      selectedAdmissions.removeWhere(
        (admissionNo) => !visibleAdmissions.contains(admissionNo),
      );

      // Automatic mode always selects eligible students
      // from the currently selected source class.
      if (automaticMode) {
        selectedAdmissions.clear();

        for (final student in results) {
          if (isEligible(student)) {
            selectedAdmissions.add(student.admissionNo);
          }
        }
      }
    });
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void searchStudents(String value) {
    _applyFilters();
  }

  // ============================================================
  // CHANGE PROMOTION PATH
  // ============================================================

  void changePromotionPath(_PromotionPath? path) {
    if (path == null) return;

    setState(() {
      selectedPath = path;
      selectedAdmissions.clear();
    });

    _applyFilters();
  }

  // ============================================================
  // AVERAGE
  // ============================================================

  double getAverage(StudentClass student) {
    return averages[student.admissionNo] ?? 0.0;
  }

  // ============================================================
  // ELIGIBILITY
  // ============================================================

  bool isEligible(StudentClass student) {
    return StudentPromotionService.isEligible(getAverage(student));
  }

  // ============================================================
  // SELECT ALL ELIGIBLE
  // ============================================================

  void selectAllEligible() {
    setState(() {
      selectedAdmissions.clear();

      for (final student in filteredStudents) {
        if (isEligible(student)) {
          selectedAdmissions.add(student.admissionNo);
        }
      }
    });
  }

  // ============================================================
  // CLEAR SELECTION
  // ============================================================

  void clearSelection() {
    setState(() {
      selectedAdmissions.clear();
    });
  }

  // ============================================================
  // SELECT ALL VISIBLE (for Manual mode)
  // ============================================================

  void selectAllVisible() {
    setState(() {
      selectedAdmissions.clear();
      for (final student in filteredStudents) {
        selectedAdmissions.add(student.admissionNo);
      }
    });
  }

  // ============================================================
  // TOGGLE STUDENT
  // ============================================================

  void toggleStudent(StudentClass student) {
    final admissionNo = student.admissionNo;

    if (automaticMode && !isEligible(student)) {
      return;
    }

    setState(() {
      if (selectedAdmissions.contains(admissionNo)) {
        selectedAdmissions.remove(admissionNo);
      } else {
        selectedAdmissions.add(admissionNo);
      }
    });
  }

  // ============================================================
  // CHANGE MODE
  // ============================================================

  void changeMode(bool automatic) {
    setState(() {
      automaticMode = automatic;
      selectedAdmissions.clear();
    });

    if (automatic) {
      selectAllEligible();
    }
  }

  // ============================================================
  // PROMOTE
  // ============================================================

  Future<void> promoteSelectedStudents() async {
    if (selectedAdmissions.isEmpty) {
      _showMessage(
        automaticMode
            ? 'There are no eligible students to promote.'
            : 'Please select at least one student.',
        Colors.orange.shade800,
      );
      return;
    }

    // ----------------------------------------------------------
    // Automatic mode validation.
    // ----------------------------------------------------------

    if (automaticMode) {
      final invalidStudents = filteredStudents.where((student) {
        return selectedAdmissions.contains(student.admissionNo) &&
            !isEligible(student);
      }).toList();

      if (invalidStudents.isNotEmpty) {
        _showMessage(
          'Automatic promotion only allows students with an average of 40% or above.',
          Colors.red.shade700,
        );
        return;
      }
    }

    final confirmed = await _showPromotionConfirmation();

    if (!mounted) return;

    if (confirmed != true) return;

    setState(() {
      promoting = true;
    });

    try {
      // --------------------------------------------------------
      // Only promote students currently visible in the selected
      // promotion path.
      // --------------------------------------------------------

      final studentsToPromote = filteredStudents.where((student) {
        return selectedAdmissions.contains(student.admissionNo);
      }).toList();

      if (studentsToPromote.isEmpty) {
        if (!mounted) return;

        setState(() {
          promoting = false;
        });

        _showMessage(
          'No students are available for this promotion path.',
          Colors.orange.shade800,
        );

        return;
      }

      // --------------------------------------------------------
      // Graduated is represented by the class name "Graduated".
      //
      // This keeps the existing StudentPromotionService API:
      //
      // promoteStudents(
      //   students: ...,
      //   newClassName: ...,
      //   newSession: ...
      // )
      // --------------------------------------------------------

      final targetBase = selectedPath.targetClass ?? 'Graduated';

      int count = 0;
      for (final student in studentsToPromote) {
        final targetClassName = buildTargetClassName(
          student.className,
          targetBase,
        );

        try {
          await StudentPromotionService.promoteStudent(
            currentAssignment: student,
            newClassName: targetClassName,
            newSession: nextSession,
          );
          await StudentPromotionService.recordPromotion(
            currentAssignment: student,
            newClassName: targetClassName,
            newSession: nextSession,
            average: getAverage(student),
          );
          count++;
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        promoting = false;
        selectedAdmissions.clear();
      });

      await loadData();

      if (!mounted) return;

      await AuditLogStorage.log(
        action: 'promotion',
        module: 'promotion',
        description:
            '$count student(s) promoted for session $currentSession → $nextSession',
        refId: currentSession,
      );

      _showMessage(
        '$count student${count == 1 ? '' : 's'} promoted successfully.',
        Colors.green.shade700,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        promoting = false;
      });

      _showMessage('Promotion failed: $e', Colors.red.shade700);
    }
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  Future<bool?> _showPromotionConfirmation() {
    final target = selectedPath.targetClass ?? 'Graduated';

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Promotion',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'You are about to promote '
            '${selectedAdmissions.length} student'
            '${selectedAdmissions.length == 1 ? '' : 's'} '
            'from ${selectedPath.sourceClass} to $target '
            'for ${_computeNextSession(currentSession)}.\n\n'
            'The previous session records will be kept.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Promote'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================


  // ============================================================
  // REPEAT SELECTED STUDENTS (same class → next session)
  // ============================================================


  Future<void> markLeftSelectedStudents() async {
    if (selectedAdmissions.isEmpty) {
      _showMessage('Please select at least one student.', Colors.orange.shade800);
      return;
    }
    if (automaticMode) {
      _showMessage(
        'Switch to Manual mode to mark students who did not return.',
        Colors.orange.shade800,
      );
      return;
    }

    final nextSession = _computeNextSession(currentSession);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as left school'),
        content: Text(
          'Mark ${selectedAdmissions.length} student(s) as LEFT SCHOOL?\n\n'
          'Use this when a student finished ${selectedPath.sourceClass} '
          'but did not return for the next class.\n\n'
          'Session: $currentSession → $nextSession',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark as left'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => promoting = true);
    try {
      final selected = Set<String>.from(selectedAdmissions);
      final source = normalizeClassName(selectedPath.sourceClass);
      var list = allSessionStudents.where((student) {
        if (!selected.contains(student.admissionNo)) return false;
        final studentClass = normalizeClassName(student.className);
        return studentClass == source || studentClass.startsWith(source);
      }).toList();
      if (list.isEmpty) {
        list = allSessionStudents
            .where((s) => selected.contains(s.admissionNo))
            .toList();
      }

      int count = 0;
      for (final student in list) {
        await StudentPromotionService.markStudentLeft(
          currentAssignment: student,
          newSession: nextSession,
          average: getAverage(student),
        );
        count++;
      }
      selectedAdmissions.clear();
      await loadData();
      if (!mounted) return;
      setState(() => promoting = false);
      _showMessage(
        '$count student(s) marked as left school → $nextSession',
        const Color(0xFF64748B),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => promoting = false);
      _showMessage('Failed: $e', Colors.red.shade700);
    }
  }

  Future<void> repeatSelectedStudents() async {
    if (selectedAdmissions.isEmpty) {
      _showMessage('Please select at least one student to repeat.', Colors.orange.shade800);
      return;
    }

    if (automaticMode) {
      _showMessage(
        'Switch to Manual mode to mark students as repeating the class.',
        Colors.orange.shade800,
      );
      return;
    }

    final nextSession = _computeNextSession(currentSession);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm repeat'),
        content: Text(
          'Mark ${selectedAdmissions.length} student(s) as REPEATING '
          '${selectedPath.sourceClass} for session $currentSession → $nextSession?\n\n'
          'They will stay in the same class in the next session.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Repeat class'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => promoting = true);

    try {
      // Snapshot selection first (do not rely on set after awaits)
      final selected = Set<String>.from(selectedAdmissions);
      final source = normalizeClassName(selectedPath.sourceClass);

      // Match like the list filter: "JSS1" matches "JSS1 A"
      final toRepeat = allSessionStudents.where((student) {
        if (!selected.contains(student.admissionNo)) return false;
        final studentClass = normalizeClassName(student.className);
        return studentClass == source || studentClass.startsWith(source);
      }).toList();

      if (toRepeat.isEmpty) {
        // Fallback: repeat by admission only (still in current session list)
        final fallback = allSessionStudents
            .where((s) => selected.contains(s.admissionNo))
            .toList();
        toRepeat.addAll(fallback);
      }

      // Deduplicate by admission no
      final unique = <String, dynamic>{};
      for (final s in toRepeat) {
        unique[s.admissionNo] = s;
      }
      final list = unique.values.toList();

      int count = 0;
      final names = <String>[];
      for (final student in list) {
        final avg = getAverage(student);
        await StudentPromotionService.repeatStudent(
          currentAssignment: student,
          newSession: nextSession,
          average: avg,
        );
        count++;
        names.add(student.studentName);
      }

      selectedAdmissions.clear();
      await loadData();

      if (!mounted) return;
      setState(() => promoting = false);
      if (count == 0) {
        _showMessage(
          'No matching students to repeat. Select students in the list first.',
          Colors.red.shade700,
        );
      } else {
        _showMessage(
          '$count student${count == 1 ? '' : 's'} repeated into $nextSession '
          '(same class): ${names.take(3).join(', ')}'
          '${names.length > 3 ? '…' : ''}',
          const Color(0xFFD97706),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => promoting = false);
      _showMessage('Repeat failed: $e', Colors.red.shade700);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(message)));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        title: const Text(
          'Student Promotion',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      // ----------------------------------------------------------
      // IMPORTANT:
      //
      // The entire page is scrollable.
      //
      // This removes the yellow/black Flutter overflow stripe that
      // appeared because the old bottom action area could not fit
      // inside the browser viewport.
      // ----------------------------------------------------------
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageTitle(),

                    const SizedBox(height: 16),

                    _buildSessionTermSelector(),

                    const SizedBox(height: 14),

                    _buildPromotionPathSelector(),

                    const SizedBox(height: 14),

                    _buildModeSelector(),

                    const SizedBox(height: 14),

                    _buildSearch(),

                    const SizedBox(height: 10),

                    _buildStudentCount(),

                    const SizedBox(height: 10),

                    _buildStudentList(),

                    const SizedBox(height: 18),

                    _buildBottomAction(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PAGE TITLE
  // ============================================================

  Widget _buildPageTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_outlined, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          const Text(
            'Promote Students',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$currentSession → $nextSession',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SESSION + TERM SELECTOR
  // ============================================================

  Widget _buildSessionTermSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session & Term',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            // -------- Current Session --------
            Expanded(
              child: DropdownButtonFormField<String>(
                value: currentSession,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Current Session',
                  prefixIcon: const Icon(Icons.calendar_today, color: primaryBlue),
                  filled: true,
                  
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                items: sessions.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: _onSessionChanged,
              ),
            ),
            const SizedBox(width: 12),
            // -------- Term --------
            Expanded(
              child: DropdownButtonFormField<String>(
                value: currentTerm,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Term (for averages)',
                  prefixIcon: const Icon(Icons.menu_book, color: primaryBlue),
                  filled: true,
                  
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                items: terms.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: _onTermChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Students will be promoted into:  $nextSession',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROMOTION PATH SELECTOR
  // ============================================================

  Widget _buildPromotionPathSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promotion Path',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),

        DropdownButtonFormField<_PromotionPath>(
          initialValue: selectedPath,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.trending_up, color: primaryBlue),
            filled: true,
            
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          items: promotionPaths.map((path) {
            return DropdownMenuItem<_PromotionPath>(
              value: path,
              child: Text(
                path.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
          onChanged: promoting ? null : changePromotionPath,
        ),

        const SizedBox(height: 7),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 17, color: primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedPath.graduated
                      ? 'SS3 students will be marked as Graduated.'
                      : 'Showing only students currently in ${selectedPath.sourceClass}.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MODE SELECTOR
  // ============================================================

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              title: 'Automatic',
              subtitle: '40% and above',
              icon: Icons.auto_awesome,
              selected: automaticMode,
              onTap: () => changeMode(true),
            ),
          ),
          Expanded(
            child: _modeButton(
              title: 'Manual',
              subtitle: 'Choose students',
              icon: Icons.touch_app_outlined,
              selected: !automaticMode,
              onTap: () => changeMode(false),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODE BUTTON
  // ============================================================

  Widget _modeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: promoting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? primaryBlue : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: selected ? primaryBlue : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      onChanged: searchStudents,
      decoration: InputDecoration(
        hintText: 'Search student, admission no. or class...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  searchStudents('');
                },
              ),
        filled: true,
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT COUNT
  // ============================================================

  Widget _buildStudentCount() {
    return Row(
      children: [
        Text(
          '${filteredStudents.length} students in ${selectedPath.sourceClass}',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const Spacer(),

        if (automaticMode)
          TextButton.icon(
            onPressed: promoting ? null : selectAllEligible,
            icon: const Icon(Icons.check_circle_outline, size: 17),
            label: const Text('Select Eligible'),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: promoting ? null : selectAllVisible,
                icon: const Icon(Icons.select_all, size: 17),
                label: const Text('Select All'),
              ),
              TextButton.icon(
                onPressed: promoting ? null : clearSelection,
                icon: const Icon(Icons.clear_all, size: 17),
                label: const Text('Clear'),
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // STUDENT LIST
  // ============================================================

  Widget _buildStudentList() {
    if (filteredStudents.isEmpty) {
      return _buildEmptyState();
    }

    return Column(children: filteredStudents.map(_studentCard).toList());
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _studentCard(StudentClass student) {
    final average = getAverage(student);
    final eligible = isEligible(student);
    final selected = selectedAdmissions.contains(student.admissionNo);

    final statusColor = eligible ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? primaryBlue : Colors.grey.shade200,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!automaticMode || eligible) {
            toggleStudent(student);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: primaryBlue,
                onChanged: automaticMode && !eligible
                    ? null
                    : (_) {
                        toggleStudent(student);
                      },
              ),

              CircleAvatar(
                radius: 23,
                backgroundColor: primaryBlue.withValues(alpha: 0.10),
                child: Text(
                  student.studentName.isEmpty
                      ? '?'
                      : student.studentName[0].toUpperCase(),
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student.admissionNo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      student.className,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${average.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      eligible ? 'ELIGIBLE' : 'BELOW 40%',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 45),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text(
            'No Students Found',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'There are no students currently assigned to '
            '${selectedPath.sourceClass} for $currentSession.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _buildBottomAction() {
    final targetClass = selectedPath.targetClass ?? 'Graduated';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ------------------------------------------------------
          // PROMOTION DESTINATION
          // ------------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.school_outlined, color: primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promotion',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selectedPath.label,
                        style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedPath.graduated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'GRADUATED',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  Text(
                    targetClass,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // PROMOTE BUTTON
          // ------------------------------------------------------
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: promoting || selectedAdmissions.isEmpty
                  ? null
                  : promoteSelectedStudents,
              icon: promoting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_upward),
              label: Text(
                promoting
                    ? 'PROCESSING...'
                    : selectedPath.graduated
                    ? 'GRADUATE SELECTED STUDENTS'
                    : automaticMode
                    ? 'PROMOTE ELIGIBLE STUDENTS'
                    : 'PROMOTE SELECTED STUDENTS',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          // Repeat is only for manual mode (not graduation path)
          if (!automaticMode && !selectedPath.graduated) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: promoting || selectedAdmissions.isEmpty
                    ? null
                    : repeatSelectedStudents,
                icon: const Icon(Icons.replay_rounded),
                label: const Text(
                  'REPEAT CLASS (SAME CLASS NEXT SESSION)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFD97706), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: promoting || selectedAdmissions.isEmpty
                    ? null
                    : markLeftSelectedStudents,
                icon: const Icon(Icons.person_off_outlined),
                label: const Text(
                  'LEFT SCHOOL (DID NOT RETURN)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFF64748B), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 7),

          Text(
            '${selectedAdmissions.length} selected · Promote moves up · Repeat keeps same class',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
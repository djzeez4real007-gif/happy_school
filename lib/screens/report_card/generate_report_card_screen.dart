import 'package:flutter/material.dart';

import '../../core/utils/sessions.dart';
import '../../core/theme/app_colors.dart';

import '../../models/report_card.dart';
import '../../services/report_card_pdf_service.dart';
import '../../models/result.dart';
import '../../models/school_class.dart';
import '../../models/student.dart';
import '../../models/student_class.dart';

import '../../services/audit_log_storage.dart';
import '../../services/class_storage.dart';
import '../../services/result_storage.dart';
import '../../services/student_storage.dart';
import '../../services/report_card_generator.dart';
import '../../services/student_class_storage.dart';
import '../../services/attendance_storage.dart';
import '../../services/student_promotion_storage.dart';

import 'report_card_screen.dart';

class GenerateReportCardScreen extends StatefulWidget {
  const GenerateReportCardScreen({super.key});

  @override
  State<GenerateReportCardScreen> createState() =>
      _GenerateReportCardScreenState();
}

class _GenerateReportCardScreenState extends State<GenerateReportCardScreen> {
  List<SchoolClass> classes = [];
  List<StudentClass> classStudents = [];
  List<Student> students = [];

  SchoolClass? selectedClass;
  Student? selectedStudent;
  StudentClass? selectedStudentClass;

  String selectedSession = "2026/2027";
  String selectedTerm = "First Term";

  bool loading = false;
  bool bulkMode = false;
  String studentSearch = '';
  final studentSearchController = TextEditingController();
  final Set<String> selectedAdmissionNos = {};

  final List<String> sessions = Sessions.list();

  final List<String> terms = const [
    'First Term',
    'Second Term',
    'Third Term',
  ];

  @override
  void dispose() {
    studentSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    final data = await ClassStorage.getClasses();
    if (!mounted) return;
    setState(() {
      classes = data;
    });
  }

  Future<void> loadStudents() async {
    if (selectedClass == null) return;

    final assignedData = await StudentClassStorage.getStudents();
    final allStudents = await StudentStorage.getStudents();

    final assignedStudents = assignedData.where((e) {
      return e.className == selectedClass!.fullClassName &&
          e.session.trim() == selectedSession;
    }).toList();

    if (!mounted) return;

    setState(() {
      classStudents = assignedStudents;
      students = [];

      for (final assigned in assignedStudents) {
        try {
          final student = allStudents.firstWhere(
            (e) => e.admissionNo == assigned.admissionNo,
          );
          students.add(student);
        } catch (_) {}
      }

      selectedStudent = null;
      selectedStudentClass = null;
    });
  }

  /// Compute class position from averages of all students in class for this term
  Future<int> _computePosition({
    required String admissionNo,
    required List<Result> studentResults,
  }) async {
    if (selectedClass == null || studentResults.isEmpty) return 1;

    // Get all students in this class+session
    final assigned = await StudentClassStorage.getStudents();
    final classmates = assigned.where((e) {
      return e.className == selectedClass!.fullClassName &&
          e.session.trim() == selectedSession;
    }).toList();

    final averages = <String, double>{};

    for (final mate in classmates) {
      final all = await ResultStorage.getStudentResults(mate.admissionNo);
      final termResults = all.where((r) {
        return r.session.trim() == selectedSession &&
            r.term.trim() == selectedTerm;
      }).toList();

      if (termResults.isEmpty) {
        averages[mate.admissionNo] = 0;
      } else {
        averages[mate.admissionNo] = termResults.fold<double>(0, (s, r) => s + r.total) /
            termResults.length;
      }
    }

    // Rank: higher average = better position
    final sorted = averages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int position = 1;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].key.trim().toLowerCase() ==
          admissionNo.trim().toLowerCase()) {
        position = i + 1;
        break;
      }
    }
    return position;
  }

  Future<({int present, int total})> _computeAttendance(String admissionNo) async {
    try {
      final records = await AttendanceStorage.getStudentAttendance(admissionNo);
      final filtered = records.where((r) {
        return r.session.trim() == selectedSession &&
            r.term.trim() == selectedTerm;
      }).toList();

      final total = filtered.length;
      final present = filtered.where((r) {
        final status = r.status.trim().toLowerCase();
        return status == 'present' || status == 'late';
      }).length;

      return (present: present, total: total);
    } catch (_) {
      return (present: 0, total: 0);
    }
  }


  Future<ReportCard?> _buildCardFor(Student student) async {
    final allResults = await ResultStorage.getStudentResults(student.admissionNo);
    final results = allResults.where((r) {
      return r.session.trim() == selectedSession &&
          r.term.trim() == selectedTerm;
    }).toList();

    final position = await _computePosition(
      admissionNo: student.admissionNo,
      studentResults: results,
    );
    final attendance = await _computeAttendance(student.admissionNo);
    final average = results.isEmpty
        ? 0.0
        : results.fold<double>(0, (s, r) => s + r.total) / results.length;

    bool? promoted;
    String? promotionStatus;
    if (selectedTerm == 'Third Term') {
      final history =
          await StudentClassStorage.getStudentHistory(student.admissionNo);
      String nextSession = selectedSession;
      try {
        final parts = selectedSession.split('/');
        if (parts.length == 2) {
          final a = int.parse(parts[0].trim());
          final b = int.parse(parts[1].trim());
          nextSession = '${a + 1}/${b + 1}';
        }
      } catch (_) {}

      String norm(String v) =>
          v.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

      final currentClassNorm = norm(selectedClass!.fullClassName);

      // Explicit repeat/promote records from Promotion module
      final promoRecords = await StudentPromotionStorage.getPromotions();
      final myPromo = promoRecords.where((p) {
        return p.admissionNo.trim().toLowerCase() ==
                student.admissionNo.trim().toLowerCase() &&
            p.fromSession.trim() == selectedSession.trim();
      }).toList();

      final wasRepeated = myPromo.any((p) => p.outcome == 'repeated');
      final wasPromoted = myPromo.any((p) => p.outcome == 'promoted');
      final wasLeft = myPromo.any((p) =>
          p.outcome == 'left' ||
          p.toClass.trim().toLowerCase() == 'left' ||
          p.toClass.trim().toLowerCase() == 'withdrawn');

      final nextAssignments = history.where((h) {
        return h.session.trim() == nextSession;
      }).toList();

      final graduatedRecord = nextAssignments
          .where((h) => h.className.trim().toLowerCase() == 'graduated')
          .toList();
      final leftRecord = nextAssignments
          .where((h) {
            final c = h.className.trim().toLowerCase();
            return c == 'left' || c == 'withdrawn';
          })
          .toList();
      final retainedRecord = nextAssignments
          .where((h) => h.className.trim().toLowerCase() == 'retained')
          .toList();

      if (wasLeft || leftRecord.isNotEmpty) {
        promoted = false;
        promotionStatus = 'left';
      } else if (wasRepeated) {
        promoted = false;
        promotionStatus = 'repeated';
      } else if (graduatedRecord.isNotEmpty) {
        promoted = true;
        promotionStatus = 'graduated';
      } else if (wasPromoted) {
        promoted = true;
        promotionStatus = 'promoted';
      } else if (nextAssignments.isNotEmpty) {
        // Infer from next-session class vs current class
        final nextClass = nextAssignments.last.className;
        final nextNorm = norm(nextClass);
        final nextLower = nextClass.trim().toLowerCase();
        if (nextLower == 'graduated') {
          promoted = true;
          promotionStatus = 'graduated';
        } else if (nextLower == 'left' || nextLower == 'withdrawn') {
          promoted = false;
          promotionStatus = 'left';
        } else if (nextNorm == currentClassNorm ||
            nextNorm.startsWith(currentClassNorm) ||
            currentClassNorm.startsWith(nextNorm)) {
          // Same class next session → repeated
          promoted = false;
          promotionStatus = 'repeated';
        } else {
          promoted = true;
          promotionStatus = 'promoted';
        }
      } else if (retainedRecord.isNotEmpty) {
        promoted = false;
        promotionStatus = 'not_promoted';
      } else {
        // Not decided yet — do not generate third term card
        return null;
      }
    }

    return ReportCardGenerator.generate(
      student: student,
      results: results,
      session: selectedSession,
      term: selectedTerm,
      className: selectedClass!.fullClassName,
      position: position,
      attendancePresent: attendance.present,
      attendanceTotal: attendance.total,
      classTeacherRemark: average >= 50
          ? "Good performance. Keep it up."
          : "Needs more effort and improvement.",
      principalRemark: average >= 50
          ? "Satisfactory progress."
          : "Parent attention required.",
      promoted: promoted,
      promotionStatus: promotionStatus,
    );
  }

  Future<void> generateReportCard() async {
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a class')),
      );
      return;
    }

    if (bulkMode) {
      if (selectedAdmissionNos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one student')),
        );
        return;
      }
      setState(() => loading = true);
      try {
        final chosen = students
            .where((s) => selectedAdmissionNos.contains(s.admissionNo))
            .toList();
        final cards = <ReportCard>[];
        for (final student in chosen) {
          final card = await _buildCardFor(student);
          if (card != null) cards.add(card);
        }
        if (!mounted) return;
        setState(() => loading = false);
        if (cards.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No report cards generated')),
          );
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _BulkReportCardsViewer(cards: cards),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk generate failed.\n$e')),
        );
      }
      return;
    }

    if (selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a student')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final reportCard = await _buildCardFor(selectedStudent!);
      if (!mounted) return;
      setState(() => loading = false);
      if (reportCard == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Third Term report cards require a promotion decision first. '
              'Complete promotion (or mark retained) in the Promotion module.',
            ),
          ),
        );
        return;
      }
      await AuditLogStorage.log(
        action: 'report_card_generated',
        module: 'report_cards',
        description:
            'Generated report card for ${selectedStudent?.fullName ?? "student"} · $selectedTerm',
        refId: selectedStudent?.admissionNo,
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportCardScreen(reportCard: reportCard),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate report card.\n$e")),
      );
    }
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      
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
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      // Title comes from AppShell; keep minimal actions
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.description_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate Report Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Single student or bulk for a whole class',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Mode toggle
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _modeChip('Single', !bulkMode, () {
                    setState(() {
                      bulkMode = false;
                      selectedAdmissionNos.clear();
                    });
                  }),
                ),
                Expanded(
                  child: _modeChip('Bulk (class)', bulkMode, () {
                    setState(() {
                      bulkMode = true;
                      selectedStudent = null;
                    });
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSession,
                  decoration: _dec('Session', Icons.calendar_today_rounded),
                  items: sessions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    setState(() {
                      selectedSession = value;
                      selectedStudent = null;
                      students = [];
                      classStudents = [];
                      selectedAdmissionNos.clear();
                    });
                    if (selectedClass != null) await loadStudents();
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedClass?.fullClassName,
                  isExpanded: true,
                  decoration: _dec('Class', Icons.class_rounded),
                  items: classes
                      .map((c) => DropdownMenuItem(
                            value: c.fullClassName,
                            child: Text(c.fullClassName),
                          ))
                      .toList(),
                  onTap: () {
                    loadClasses();
                  },
                  onChanged: (value) async {
                    setState(() {
                      if (value == null) {
                        selectedClass = null;
                      } else {
                        try {
                          selectedClass = classes.firstWhere(
                            (c) => c.fullClassName == value,
                          );
                        } catch (_) {
                          selectedClass = null;
                        }
                      }
                      selectedStudent = null;
                      students = [];
                      classStudents = [];
                      selectedAdmissionNos.clear();
                    });
                    await loadStudents();
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedTerm,
                  decoration: _dec('Term', Icons.menu_book_rounded),
                  items: terms
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedTerm = value);
                  },
                ),
                if (!bulkMode) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: studentSearchController,
                    onChanged: (v) => setState(() => studentSearch = v),
                    decoration: _dec('Search student', Icons.search_rounded).copyWith(
                      hintText: 'Type name or admission number…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (studentSearch.trim().isNotEmpty) ...[
                    ...students.where((s) {
                      final q = studentSearch.trim().toLowerCase();
                      return s.fullName.toLowerCase().contains(q) ||
                          s.admissionNo.toLowerCase().contains(q);
                    }).take(12).map((s) {
                      final sel = selectedStudent?.admissionNo == s.admissionNo;
                      return ListTile(
                        dense: true,
                        selected: sel,
                        leading: Icon(
                          sel ? Icons.check_circle : Icons.person_outline,
                          color: sel ? AppColors.primary : null,
                        ),
                        title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(s.admissionNo),
                        onTap: () => setState(() {
                          selectedStudent = s;
                          studentSearchController.text = s.fullName;
                          studentSearch = s.fullName;
                        }),
                      );
                    }),
                  ] else if (selectedStudent != null)
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.check_circle, color: AppColors.primary),
                      title: Text(selectedStudent!.fullName),
                      subtitle: Text(selectedStudent!.admissionNo),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          selectedStudent = null;
                          studentSearch = '';
                          studentSearchController.clear();
                        }),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Start typing to find a student',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                ],
              ],
            ),
          ),

          if (bulkMode && students.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder(context)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Students (${selectedAdmissionNos.length}/${students.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (selectedAdmissionNos.length == students.length) {
                              selectedAdmissionNos.clear();
                            } else {
                              selectedAdmissionNos
                                ..clear()
                                ..addAll(students.map((s) => s.admissionNo));
                            }
                          });
                        },
                        child: Text(
                          selectedAdmissionNos.length == students.length
                              ? 'Clear all'
                              : 'Select all',
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...students.map((s) {
                    final checked =
                        selectedAdmissionNos.contains(s.admissionNo);
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      title: Text(s.fullName),
                      subtitle: Text(s.admissionNo),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selectedAdmissionNos.add(s.admissionNo);
                          } else {
                            selectedAdmissionNos.remove(s.admissionNo);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: loading ? null : generateReportCard,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.assignment_rounded),
              label: Text(
                loading
                    ? 'Generating...'
                    : (bulkMode
                        ? 'GENERATE SELECTED (${selectedAdmissionNos.length})'
                        : 'GENERATE REPORT CARD'),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkReportCardsViewer extends StatefulWidget {
  final List<ReportCard> cards;
  const _BulkReportCardsViewer({required this.cards});

  @override
  State<_BulkReportCardsViewer> createState() => _BulkReportCardsViewerState();
}

class _BulkReportCardsViewerState extends State<_BulkReportCardsViewer> {
  bool busy = false;

  Future<void> _run(Future<void> Function() action, String okMsg) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(okMsg),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    return Scaffold(
      appBar: AppBar(
        title: Text('Generated (${cards.length})'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text(
              'Generate all PDFs creates one file with every student report. '
              'Print or share it, then send to parents (WhatsApp, email, etc.). '
              'Tap a student to open one report only.',
              style: TextStyle(height: 1.35, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy
                        ? null
                        : () => _run(
                              () => ReportCardPdfService.printAllReportCards(
                                    cards,
                                  ),
                              'Print / save dialog opened for all reports',
                            ),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(
                      busy ? 'Working…' : 'Generate all PDFs',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => _run(
                              () => ReportCardPdfService.shareAllReportCards(
                                    cards,
                                  ),
                              'Share sheet opened — send the PDF to parents',
                            ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text(
                      'Share all',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = cards[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(
                      c.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle:
                        Text('${c.className} · ${c.session} · ${c.term}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportCardScreen(reportCard: c),
                        ),
                      );
                    },
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

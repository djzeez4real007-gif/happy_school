import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../models/school_class.dart';
import '../../models/student.dart';
import '../../services/class_storage.dart';
import '../../services/result_storage.dart';
import '../../services/student_class_storage.dart';
import '../../services/student_storage.dart';

/// Shows each student's average for First, Second and Third Term.
class ClassTermAveragesScreen extends StatefulWidget {
  const ClassTermAveragesScreen({super.key});

  @override
  State<ClassTermAveragesScreen> createState() =>
      _ClassTermAveragesScreenState();
}

class _ClassTermAveragesScreenState extends State<ClassTermAveragesScreen> {
  List<SchoolClass> classes = [];
  SchoolClass? selectedClass;
  String selectedSession = Sessions.current();
  final sessions = Sessions.list();

  bool loading = false;
  bool loadedOnce = false;
  List<_Row> rows = [];
  String query = '';

  static const terms = ['First Term', 'Second Term', 'Third Term'];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final data = await ClassStorage.getClasses();
    data.sort(
      (a, b) => a.fullClassName.toLowerCase().compareTo(
            b.fullClassName.toLowerCase(),
          ),
    );
    if (!mounted) return;
    setState(() => classes = data);
  }

  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

  /// JSS1 matches JSS1A, JSS1 B, etc.
  bool _classMatches(String studentClass, String selected) {
    final a = _norm(studentClass);
    final b = _norm(selected);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (a.startsWith(b) || b.startsWith(a)) return true;
    return false;
  }

  /// Average from live result entries (ca1+ca2+exam) for session+term.
  Future<double> _averageFromResults({
    required String admissionNo,
    required String session,
    required String term,
  }) async {
    final all = await ResultStorage.getResults();
    final targetAdm = admissionNo.trim().toLowerCase();
    final targetSess = session.trim().toLowerCase();
    final targetTerm = term.trim().toLowerCase();

    final matches = all.where((r) {
      return r.admissionNo.trim().toLowerCase() == targetAdm &&
          r.session.trim().toLowerCase() == targetSess &&
          r.term.trim().toLowerCase() == targetTerm;
    }).toList();

    if (matches.isEmpty) return 0;

    double sum = 0;
    for (final r in matches) {
      sum += r.total;
    }
    return sum / matches.length;
  }

  Future<void> _loadAverages() async {
    if (selectedClass == null) return;
    setState(() => loading = true);

    final className = selectedClass!.fullClassName;
    final assignments = await StudentClassStorage.getStudents();
    final allStudents = await StudentStorage.getStudents();
    final byAdmission = <String, Student>{
      for (final s in allStudents) s.admissionNo.trim().toLowerCase(): s,
    };

    final students = <Map<String, String>>[];
    final seen = <String>{};

    for (final a in assignments) {
      if (a.session.trim() != selectedSession.trim()) continue;
      if (!_classMatches(a.className, className)) continue;
      final key = a.admissionNo.trim().toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);

      final st = byAdmission[key];
      final name = (st?.fullName.isNotEmpty == true)
          ? st!.fullName
          : (a.studentName.isNotEmpty ? a.studentName : a.admissionNo);

      students.add({
        'admissionNo': a.admissionNo,
        'name': name,
      });
    }

    students.sort(
      (a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
    );

    final out = <_Row>[];
    for (final s in students) {
      final avgs = <String, double>{};
      for (final term in terms) {
        avgs[term] = await _averageFromResults(
          admissionNo: s['admissionNo']!,
          session: selectedSession,
          term: term,
        );
      }
      out.add(
        _Row(
          admissionNo: s['admissionNo']!,
          name: s['name']!,
          averages: avgs,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      rows = out;
      loading = false;
      loadedOnce = true;
    });
  }

  List<_Row> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.admissionNo.toLowerCase().contains(q))
        .toList();
  }

  Color _avgColor(double v) {
    if (v <= 0) return const Color(0xFF94A3B8);
    if (v >= 50) return const Color(0xFF059669);
    if (v >= 40) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  String _label(String term) {
    if (term == 'First Term') return '1st';
    if (term == 'Second Term') return '2nd';
    return '3rd';
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    final withAnyResult =
        list.where((r) => r.averages.values.any((v) => v > 0)).length;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          // ===== Header =====
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 16,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Term Averages',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    if (selectedClass != null)
                      IconButton(
                        onPressed: _loadAverages,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '1st · 2nd · 3rd term averages from entered results',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _headerDropdown(
                    value: sessions.contains(selectedSession)
                        ? selectedSession
                        : sessions.first,
                    items: sessions,
                    onChanged: (v) async {
                      if (v == null) return;
                      selectedSession = v;
                      if (selectedClass != null) await _loadAverages();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SchoolClass>(
                        value: selectedClass,
                        isExpanded: true,
                        hint: const Text(
                          'Select class',
                          style: TextStyle(color: Colors.white70),
                        ),
                        dropdownColor: const Color(0xFF1E3A8A),
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        items: classes
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.fullClassName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) async {
                          selectedClass = v;
                          await _loadAverages();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Search student…',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                if (loadedOnce && !loading)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                    child: Text(
                      '${list.length} students · $withAnyResult with results',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ===== Body =====
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : selectedClass == null
                    ? Center(
                        child: Text(
                          'Select a class to view term averages',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : list.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                loadedOnce
                                    ? 'No students assigned to ${selectedClass!.fullClassName} for $selectedSession.\n\nCheck class assignment for this session.'
                                    : 'Select a class',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final r = list[index];
                              final overall = r.averages.values
                                      .where((v) => v > 0)
                                      .toList();
                              final overallAvg = overall.isEmpty
                                  ? 0.0
                                  : overall.reduce((a, b) => a + b) /
                                      overall.length;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.card(context),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.cardBorder(context),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF1D4ED8),
                                                Color(0xFF60A5FA),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            r.name.isNotEmpty
                                                ? r.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
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
                                                r.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                r.admissionNo,
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary(
                                                          context),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (overallAvg > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _avgColor(overallAvg)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              overallAvg.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: _avgColor(overallAvg),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: terms.map((term) {
                                        final avg = r.averages[term] ?? 0;
                                        return Expanded(
                                          child: Container(
                                            margin: EdgeInsets.only(
                                              right: term == 'Third Term'
                                                  ? 0
                                                  : 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _avgColor(avg)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _avgColor(avg)
                                                    .withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  _label(term),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: _avgColor(avg),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  avg <= 0
                                                      ? '—'
                                                      : avg.toStringAsFixed(1),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                    color: _avgColor(avg),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
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

  Widget _headerDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E3A8A),
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Row {
  final String admissionNo;
  final String name;
  final Map<String, double> averages;

  _Row({
    required this.admissionNo,
    required this.name,
    required this.averages,
  });
}

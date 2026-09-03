import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../models/result.dart';
import '../../services/auth_service.dart';
import '../../services/result_storage.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  bool loading = true;
  List<Result> results = [];
  late String session;
  String term = 'First Term';
  final terms = const ['First Term', 'Second Term', 'Third Term'];

  String get admissionNo {
    final u = AuthService.currentUser;
    if (u == null) return '';
    if (u.childrenAdmissionNos.isNotEmpty) return u.childrenAdmissionNos.first;
    return u.username;
  }

  @override
  void initState() {
    super.initState();
    session = Sessions.current();
    final list = Sessions.list();
    if (!list.contains(session) && list.isNotEmpty) {
      session = list.first;
    }
    // Prefer working year if present
    if (list.contains('2026/2027')) session = '2026/2027';
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final adm = admissionNo.trim();
    List<Result> all = [];
    try {
      all = await ResultStorage.getStudentResults(adm);
    } catch (_) {
      all = [];
    }

    final filtered = all
        .where((r) =>
            r.session.trim() == session.trim() &&
            r.term.trim().toLowerCase() == term.trim().toLowerCase())
        .toList()
      ..sort((a, b) => a.subjectName.compareTo(b.subjectName));

    if (!mounted) return;
    setState(() {
      results = filtered;
      loading = false;
    });
  }

  Color _gradeColor(String g) {
    final x = g.toUpperCase();
    if (x.startsWith('A') || x.startsWith('B')) return const Color(0xFF059669);
    if (x.startsWith('C')) return AppColors.primary;
    if (x.startsWith('D') || x.startsWith('E')) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final avg = results.isEmpty
        ? 0.0
        : results.map((r) => r.total).fold(0.0, (a, b) => a + b) /
            results.length;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('My results'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: AppColors.primary,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: Sessions.list().contains(session)
                            ? session
                            : null,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          labelText: 'Session',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white,
                        items: Sessions.list()
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style:
                                          const TextStyle(color: Colors.black87)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => session = v);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: term,
                        decoration: InputDecoration(
                          labelText: 'Term',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white,
                        items: terms
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style:
                                          const TextStyle(color: Colors.black87)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => term = v);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
                if (results.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Average: ${avg.toStringAsFixed(1)} · ${results.length} subject(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No results for $session · $term',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final r = results[i];
                          final color = _gradeColor(r.grade);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.cardBorder(context)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.subjectName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'CA1 ${r.ca1.toStringAsFixed(0)}  ·  CA2 ${r.ca2.toStringAsFixed(0)}  ·  Exam ${r.exam.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color:
                                              AppColors.textSecondary(context),
                                        ),
                                      ),
                                      Text(
                                        r.remark,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      r.total.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        r.grade,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
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
}

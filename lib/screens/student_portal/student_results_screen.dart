import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../services/auth_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/result.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  bool loading = true;
  List<Result> results = [];
  String session = Sessions.list().isNotEmpty ? Sessions.list().first : '2026/2027';
  String term = 'First Term';
  final terms = const ['First Term', 'Second Term', 'Third Term'];

  String get admissionNo =>
      AuthService.currentUser?.username ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    List<Result> all = [];
    try {
      if (!Hive.isBoxOpen('results')) {
        await Hive.openBox('results');
      }
      final box = Hive.box('results');
      for (final raw in box.values) {
        try {
          final r = Result.fromMap(Map<String, dynamic>.from(raw as Map));
          if (r.admissionNo.trim().toLowerCase() ==
              admissionNo.trim().toLowerCase()) {
            all.add(r);
          }
        } catch (_) {}
      }
    } catch (_) {}
    final filtered = all
        .where((r) => r.session == session && r.term == term)
        .toList()
      ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
    if (!mounted) return;
    setState(() {
      results = filtered;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('My results'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: session,
                    decoration: const InputDecoration(
                      labelText: 'Session',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: Sessions.list()
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
                    decoration: const InputDecoration(
                      labelText: 'Term',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: terms
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? const Center(child: Text('No results for this session/term'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final r = results[i];
                          return Card(
                            child: ListTile(
                              title: Text(
                                r.subjectName,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                'CA1 ${r.ca1.toStringAsFixed(0)} · CA2 ${r.ca2.toStringAsFixed(0)} · Exam ${r.exam.toStringAsFixed(0)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    r.total.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(r.grade, style: const TextStyle(fontSize: 12)),
                                ],
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

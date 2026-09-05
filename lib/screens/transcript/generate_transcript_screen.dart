import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';

import '../../core/theme/app_colors.dart';
import '../../models/result.dart';
import '../../services/result_storage.dart';
import '../../services/student_storage.dart';
import '../../services/transcript_pdf_service.dart';

class GenerateTranscriptScreen extends StatefulWidget {
  const GenerateTranscriptScreen({super.key});

  @override
  State<GenerateTranscriptScreen> createState() =>
      _GenerateTranscriptScreenState();
}

class _GenerateTranscriptScreenState extends State<GenerateTranscriptScreen> {
  final searchCtrl = TextEditingController();
  bool loading = true;
  bool loadingStudent = false;
  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> filtered = [];
  Map<String, dynamic>? selected;
  List<Result> results = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => loading = true);
    try {
      final list = await StudentStorage.getStudents();
      final rows = <Map<String, dynamic>>[];
      for (final s in list) {
        try {
          rows.add({
            'admissionNo': s.admissionNo,
            'fullName': s.fullName,
            'gender': s.gender,
            'dateOfBirth': s.dateOfBirth,
            'passport': s.passport,
          });
        } catch (_) {}
      }
      rows.sort((a, b) => '${a['fullName']}'
          .toLowerCase()
          .compareTo('${b['fullName']}'.toLowerCase()));
      if (!mounted) return;
      setState(() {
        allStudents = rows;
        filtered = rows;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _filter(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filtered = allStudents;
      } else {
        filtered = allStudents.where((s) {
          return '${s['fullName']}'.toLowerCase().contains(query) ||
              '${s['admissionNo']}'.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _select(Map<String, dynamic> s) async {
    setState(() {
      selected = s;
      loadingStudent = true;
      results = [];
    });
    final adm = '${s['admissionNo']}'.trim();
    // Project API: getStudentResults (not getForStudent)
    List<Result> list = await ResultStorage.getStudentResults(adm);
    list.sort((a, b) {
      final sc = b.session.compareTo(a.session);
      if (sc != 0) return sc;
      final tOrder = _termOrder(a.term).compareTo(_termOrder(b.term));
      if (tOrder != 0) return tOrder;
      return a.subjectName.compareTo(b.subjectName);
    });
    if (!mounted) return;
    setState(() {
      results = list;
      loadingStudent = false;
    });
  }

  int _termOrder(String t) {
    final x = t.toLowerCase();
    if (x.contains('first')) return 1;
    if (x.contains('second')) return 2;
    if (x.contains('third')) return 3;
    return 9;
  }

  Map<String, Map<String, List<Result>>> get grouped {
    final map = <String, Map<String, List<Result>>>{};
    for (final r in results) {
      map.putIfAbsent(r.session, () => {});
      map[r.session]!.putIfAbsent(r.term, () => []);
      map[r.session]![r.term]!.add(r);
    }
    return map;
  }

  Future<void> _print() async {
    if (selected == null) return;
    try {
      await TranscriptPdfService.printTranscript(
        student: selected!,
        results: results,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to print: $e')),
      );
    }
  }

  Future<void> _share() async {
    if (selected == null) return;
    try {
      await TranscriptPdfService.shareTranscript(
        student: selected!,
        results: results,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        leading: AppBack.leading(context),
        title: const Text('Academic Transcript'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (selected != null && results.isNotEmpty) ...[
            IconButton(
              tooltip: 'Print PDF',
              onPressed: _print,
              icon: const Icon(Icons.print_rounded),
            ),
            IconButton(
              tooltip: 'Share PDF',
              onPressed: _share,
              icon: const Icon(Icons.share_rounded),
            ),
          ],
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 720;
                if (narrow) {
                  return selected == null
                      ? _studentListPane()
                      : Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.arrow_back),
                              title: Text('${selected!['fullName']}'),
                              onTap: () => setState(() {
                                selected = null;
                                results = [];
                              }),
                            ),
                            Expanded(
                              child: loadingStudent
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : _buildTranscriptBody(),
                            ),
                          ],
                        );
                }
                return Row(
                  children: [
                    SizedBox(width: 300, child: _studentListPane()),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: selected == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_edu_rounded,
                                      size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Select a student to view transcript',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : loadingStudent
                              ? const Center(child: CircularProgressIndicator())
                              : _buildTranscriptBody(),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _studentListPane() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search name or admission…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: AppColors.card(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _filter,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final s = filtered[i];
              final adm = '${s['admissionNo']}';
              final name = '${s['fullName']}';
              final isSel =
                  selected != null && '${selected!['admissionNo']}' == adm;
              return ListTile(
                selected: isSel,
                selectedTileColor:
                    AppColors.primary.withValues(alpha: 0.08),
                leading: CircleAvatar(
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(adm, style: const TextStyle(fontSize: 12)),
                onTap: () => _select(s),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptBody() {
    final s = selected!;
    final g = grouped;
    final sessions = g.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OFFICIAL ACADEMIC TRANSCRIPT',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${s['fullName']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Admission: ${s['admissionNo']}'
                '${'${s['gender']}'.trim().isNotEmpty ? '  ·  ${s['gender']}' : ''}',
                style: const TextStyle(color: Colors.white70),
              ),
              if ('${s['dateOfBirth']}'.trim().isNotEmpty)
                Text(
                  'Date of birth: ${s['dateOfBirth']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: results.isEmpty ? null : _print,
                    icon: Icon(Icons.print_rounded, size: 18),
                    label: const Text('Print PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: results.isEmpty ? null : _share,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (results.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder(context)),
            ),
            child: const Text(
              'No academic results recorded for this student yet.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...sessions.map((session) {
            final termsMap = g[session]!;
            final terms = termsMap.keys.toList()
              ..sort((a, b) => _termOrder(a).compareTo(_termOrder(b)));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Text(
                    'Session $session',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                ...terms.map((term) {
                  final list = termsMap[term]!;
                  final avg = list.isEmpty
                      ? 0.0
                      : list.map((r) => r.total).fold(0.0, (a, b) => a + b) /
                          list.length;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.cardBorder(context)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  term,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                'Avg ${avg.toStringAsFixed(1)} · ${list.length} subject(s)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 36,
                            dataRowMinHeight: 32,
                            dataRowMaxHeight: 40,
                            columns: const [
                              DataColumn(label: Text('Subject')),
                              DataColumn(label: Text('CA1')),
                              DataColumn(label: Text('CA2')),
                              DataColumn(label: Text('Exam')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Grade')),
                              DataColumn(label: Text('Remark')),
                            ],
                            rows: list
                                .map(
                                  (r) => DataRow(
                                    cells: [
                                      DataCell(Text(r.subjectName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600))),
                                      DataCell(Text(r.ca1.toStringAsFixed(0))),
                                      DataCell(Text(r.ca2.toStringAsFixed(0))),
                                      DataCell(Text(r.exam.toStringAsFixed(0))),
                                      DataCell(Text(
                                        r.total.toStringAsFixed(0),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800),
                                      )),
                                      DataCell(Text(r.grade)),
                                      DataCell(Text(r.remark)),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
      ],
    );
  }
}

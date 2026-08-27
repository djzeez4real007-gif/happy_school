import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/audit_log.dart';
import '../../services/audit_log_storage.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditLog> logs = [];
  bool loading = true;
  String query = '';
  String selectedModule = 'All';
  String selectedSession = 'All Sessions';
  String selectedTerm = 'All Terms';

  final List<String> sessions = [
    'All Sessions',
    ...List.generate(30, (i) {
      final y = 2024 + i;
      return '$y/${y + 1}';
    }),
  ];

  final List<String> terms = const [
    'All Terms',
    'First Term',
    'Second Term',
    'Third Term',
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final data = await AuditLogStorage.getAll();
    if (!mounted) return;
    setState(() {
      logs = data;
      loading = false;
    });
  }

  List<String> get modules {
    final set = <String>{};
    for (final e in logs) {
      if (e.module.trim().isNotEmpty) set.add(e.module.trim());
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  bool _matchesSession(AuditLog e) {
    if (selectedSession == 'All Sessions') return true;
    final s = (e.session ?? '').trim();
    if (s == selectedSession) return true;
    final blob = '${e.description} ${e.refId ?? ''}'.toLowerCase();
    return blob.contains(selectedSession.toLowerCase());
  }

  bool _matchesTerm(AuditLog e) {
    if (selectedTerm == 'All Terms') return true;
    final t = (e.term ?? '').trim();
    if (t.toLowerCase() == selectedTerm.toLowerCase()) return true;
    final blob = '${e.description} ${e.refId ?? ''}'.toLowerCase();
    return blob.contains(selectedTerm.toLowerCase());
  }

  List<AuditLog> get filtered {
    final q = query.trim().toLowerCase();
    return logs.where((e) {
      if (selectedModule != 'All' && e.module != selectedModule) return false;
      if (!_matchesSession(e)) return false;
      if (!_matchesTerm(e)) return false;
      if (q.isEmpty) return true;
      return e.description.toLowerCase().contains(q) ||
          e.action.toLowerCase().contains(q) ||
          e.userName.toLowerCase().contains(q) ||
          e.module.toLowerCase().contains(q) ||
          (e.refId ?? '').toLowerCase().contains(q) ||
          (e.session ?? '').toLowerCase().contains(q) ||
          (e.term ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String _formatTime(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('Audit Log'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: InputDecoration(
                      hintText: 'Search action, user, description…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.card(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth > 640;
                      Widget sessionDd = DropdownButtonFormField<String>(
                        value: sessions.contains(selectedSession)
                            ? selectedSession
                            : 'All Sessions',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Session',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: sessions
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => selectedSession = v);
                        },
                      );
                      Widget termDd = DropdownButtonFormField<String>(
                        value: selectedTerm,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Term',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: terms
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => selectedTerm = v);
                        },
                      );
                      Widget moduleDd = DropdownButtonFormField<String>(
                        value: modules.contains(selectedModule)
                            ? selectedModule
                            : 'All',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Module',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: modules
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => selectedModule = v);
                        },
                      );
                      if (wide) {
                        return Row(
                          children: [
                            Expanded(child: sessionDd),
                            const SizedBox(width: 8),
                            Expanded(child: termDd),
                            const SizedBox(width: 8),
                            Expanded(child: moduleDd),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          sessionDd,
                          const SizedBox(height: 8),
                          termDd,
                          const SizedBox(height: 8),
                          moduleDd,
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${list.length} record${list.length == 1 ? '' : 's'} (login/logout excluded)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary(context),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No audit records'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final e = list[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.cardBorder(context),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(e.module),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatTime(e.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    e.action
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1D4ED8),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e.description,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'By: ${e.userName} (${e.userRole})${e.refId != null ? ' · Ref: ${e.refId}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color:
                                          AppColors.textSecondary(context),
                                    ),
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

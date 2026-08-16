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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AuditLogStorage.getAll();
    if (!mounted) return;
    setState(() {
      logs = data;
      loading = false;
    });
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y  $h:$min';
    } catch (_) {
      return iso;
    }
  }

  List<AuditLog> get filtered {
    if (query.trim().isEmpty) return logs;
    final q = query.toLowerCase();
    return logs
        .where((e) =>
            e.description.toLowerCase().contains(q) ||
            e.userName.toLowerCase().contains(q) ||
            e.module.toLowerCase().contains(q) ||
            e.action.toLowerCase().contains(q) ||
            (e.refId ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('Audit Log'),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search actions, users, modules…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No audit entries yet',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final e = filtered[index];
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
                                    'By: ${e.userName} (${e.userRole})'
                                    '${e.refId != null ? ' · Ref: ${e.refId}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary(context),
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

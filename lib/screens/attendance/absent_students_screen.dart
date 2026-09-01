import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sessions.dart';
import '../../services/attendance_storage.dart';

class AbsentStudentsScreen extends StatefulWidget {
  const AbsentStudentsScreen({super.key});

  @override
  State<AbsentStudentsScreen> createState() => _AbsentStudentsScreenState();
}

class _AbsentStudentsScreenState extends State<AbsentStudentsScreen> {
  bool loading = true;
  late String session;
  final sessions = Sessions.list();
  List<Map<String, String>> rows = [];

  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    session = Sessions.current();
    if (!sessions.contains(session) && sessions.isNotEmpty) {
      session = sessions.first;
    }
    _load();
  }

  bool _isToday(String dateStr) {
    try {
      final d = DateTime.tryParse(dateStr);
      if (d != null) {
        final now = DateTime.now();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }
      final p = dateStr.split(RegExp(r'[/-]'));
      if (p.length >= 3) {
        final a = int.tryParse(p[0]);
        final b = int.tryParse(p[1]);
        final c = int.tryParse(p[2]);
        if (a == null || b == null || c == null) return false;
        final now = DateTime.now();
        // support yyyy-mm-dd and dd/mm/yyyy
        if (a > 31) {
          return a == now.year && b == now.month && c == now.day;
        }
        return a == now.day && b == now.month && c == now.year;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    List all = [];
    try {
      all = await AttendanceStorage.getAttendance();
    } catch (_) {
      all = [];
    }

    final sessionNorm = session.trim().toLowerCase();
    final list = <Map<String, String>>[];
    final seen = <String>{};

    for (final a in all) {
      try {
        final status = '${a.status}'.trim().toLowerCase();
        if (!(status.contains('absent') || status == 'a')) continue;

        final date = '${a.date}';
        if (!_isToday(date)) continue;

        final sess = '${a.session}'.trim().toLowerCase();
        if (sess.isNotEmpty && sess != sessionNorm) continue;

        final adm = '${a.admissionNo}'.trim().toLowerCase();
        if (adm.isEmpty || seen.contains(adm)) continue;
        seen.add(adm);

        list.add({
          'name': '${a.studentName}',
          'admissionNo': '${a.admissionNo}',
          'className': '${a.className}',
          'date': date,
        });
      } catch (_) {}
    }

    list.sort((a, b) => a['name']!.compareTo(b['name']!));

    if (!mounted) return;
    setState(() {
      rows = list;
      loading = false;
    });
  }

  String get _todayLabel {
    final n = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${n.day} ${months[n.month - 1]} ${n.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Absent today',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Premium header + session filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_off_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Students absent today',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _todayLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${rows.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sessions.contains(session) ? session : null,
                      isExpanded: true,
                      hint: const Text('Select session'),
                      icon: const Icon(Icons.expand_more_rounded),
                      items: sessions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => session = v);
                        await _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.verified_user_outlined,
                                  size: 36,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No absences today',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Nobody is marked absent for $session on $_todayLabel.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          final name = r['name'] ?? '';
                          final initial =
                              name.isNotEmpty ? name[0].toUpperCase() : '?';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.cardBorder(context),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Colors.red.shade50,
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${r['admissionNo']} · ${r['className']}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12.5,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Absent',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
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

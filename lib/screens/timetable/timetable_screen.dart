import 'package:flutter/material.dart';

import '../../core/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../models/timetable.dart';
import '../../services/audit_log_storage.dart';
import '../../services/auth_service.dart';
import '../../services/timetable_config.dart';
import '../../services/class_storage.dart';
import '../../services/timetable_storage.dart';
import '../../services/subject_teacher_service.dart';
import 'timetable_form_screen.dart';

/// Classic school grid: days as rows, periods as columns (notebook style).
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  bool get canEdit =>
      Permissions.canConfigureTimetable(AuthService.currentRole);

  List<Timetable> timetables = [];
  bool loading = true;
  String selectedClass = 'All Classes';
  List<String> allClassNames = [];

  static const _days = TimetableConfig.days;

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    setState(() => loading = true);
    var data = await TimetableStorage.getTimetables();

    // Subject teachers: only their periods
    if (SubjectTeacherService.isSubjectTeacher) {
      final me = await SubjectTeacherService.linkedTeacher();
      final codes = await SubjectTeacherService.mySubjectCodes();
      final names = await SubjectTeacherService.mySubjectNames();
      final filtered = <Timetable>[];
      for (final e in data) {
        final mine = await SubjectTeacherService.timetableEntryIsMine(
          entryTeacher: e.teacher,
          entrySubject: e.subject,
          myCodes: codes,
          myNames: names,
          me: me,
        );
        if (mine) filtered.add(e);
      }
      data = filtered;
    }

    final names = <String>{};
    try {
      final classes = await ClassStorage.getClasses();
      for (final c in classes) {
        final n = c.fullClassName.trim();
        if (n.isNotEmpty) names.add(n);
      }
    } catch (_) {}
    for (final t in data) {
      final n = t.className.trim();
      if (n.isNotEmpty) names.add(n);
    }
    if (!mounted) return;
    setState(() {
      timetables = data;
      allClassNames = names.toList()..sort();
      loading = false;
    });
  }

  List<String> get classOptions {
    final set = <String>{...allClassNames};
    for (final t in timetables) {
      final c = t.className.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return ['All Classes', ...list];
  }

  List<String> get classesWithTimetable {
    final set = <String>{};
    for (final t in timetables) {
      final c = t.className.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Prefer Mon–Thu period list (includes Short/Long Break).
  List<TimetableSlot> get slots => TimetableConfig.mondayToThursday;

  List<Timetable> get _scoped {
    if (selectedClass == 'All Classes') return timetables;
    return timetables.where((e) => e.className == selectedClass).toList();
  }

  bool _matchesSlot(Timetable entry, TimetableSlot slot) {
    final p = entry.period.trim().toLowerCase();
    final name = slot.name.trim().toLowerCase();
    final time = slot.time.trim().toLowerCase();
    if (p == name || p == slot.displayText.toLowerCase()) return true;
    if (p.startsWith(name)) return true;
    if (name.isNotEmpty && p.contains(name)) return true;
    // Match by time fragment e.g. "8:00 AM - 8:45 AM"
    if (time.isNotEmpty && p.contains(time)) return true;
    return false;
  }

  /// Cell content for day + period. Breaks show label only.
  Timetable? cellEntry(String day, TimetableSlot slot) {
    if (slot.isBreak) return null;
    final matches = _scoped
        .where((e) => e.day == day && _matchesSlot(e, slot))
        .toList();
    if (matches.isEmpty) return null;
    // Prefer exact class filter; otherwise first match
    return matches.first;
  }

  int indexOfEntry(Timetable t) {
    return timetables.indexWhere((e) => e.id == t.id);
  }

  Future<void> copyTimetableDialog() async {
    final sources = classesWithTimetable;
    if (sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a timetable for at least one class first.'),
        ),
      );
      return;
    }

    String source = selectedClass != 'All Classes' && sources.contains(selectedClass)
        ? selectedClass
        : sources.first;
    final selected = <String>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final targets = allClassNames.isNotEmpty
                ? allClassNames
                : classOptions.where((c) => c != 'All Classes').toList();
            return AlertDialog(
              title: const Text('Copy timetable'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Copy all periods from one class to other classes. '
                        'Existing day+period slots on the target are skipped.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: source,
                        decoration: const InputDecoration(
                          labelText: 'Copy from',
                          border: OutlineInputBorder(),
                        ),
                        items: sources
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setLocal(() {
                            source = v;
                            selected.remove(v);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Copy to',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setLocal(() {
                                selected
                                  ..clear()
                                  ..addAll(
                                    targets.where((c) => c != source),
                                  );
                              });
                            },
                            child: const Text('Select all'),
                          ),
                          TextButton(
                            onPressed: () => setLocal(() => selected.clear()),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...targets.map((c) {
                        final isSource = c == source;
                        return CheckboxListTile(
                          dense: true,
                          value: isSource ? false : selected.contains(c),
                          onChanged: isSource
                              ? null
                              : (v) {
                                  setLocal(() {
                                    if (v == true) {
                                      selected.add(c);
                                    } else {
                                      selected.remove(c);
                                    }
                                  });
                                },
                          title: Text(
                            isSource ? '$c (source)' : c,
                            style: TextStyle(
                              color: isSource ? Colors.grey : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Copy to ${selected.length} class(es)'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || !mounted) return;

    final count = await TimetableStorage.copyClassToClasses(
      sourceClass: source,
      targetClasses: selected.toList(),
    );
    await AuditLogStorage.log(
      action: 'timetable_copied',
      module: 'timetable',
      description:
          'Copied timetable from $source to ${selected.length} class(es) ($count entries)',
    );
    if (!mounted) return;
    await loadTimetable();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text(
          count == 0
              ? 'Nothing new to copy (targets may already have those periods).'
              : 'Copied $count period(s) from $source.',
        ),
      ),
    );
  }

  Future<void> addTimetable() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimetableFormScreen()),
    );
    if (!mounted) return;
    await loadTimetable();
  }

  Future<void> editTimetable(Timetable timetable, int index) async {
    if (index < 0) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TimetableFormScreen(timetable: timetable, index: index),
      ),
    );
    if (!mounted) return;
    await loadTimetable();
  }

  Future<void> deleteTimetable(Timetable timetable, int index) async {
    if (index < 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry'),
        content: Text(
          'Delete ${timetable.subject} · ${timetable.day} · ${timetable.period}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await TimetableStorage.deleteTimetable(index);
    await AuditLogStorage.log(
      action: 'timetable_deleted',
      module: 'timetable',
      description: 'Timetable entry deleted',
    );
    if (!mounted) return;
    await loadTimetable();
  }

  void _onCellTap(String day, TimetableSlot slot, Timetable? entry) {
    if (slot.isBreak) return;
    if (entry != null) {
      final idx = indexOfEntry(entry);
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  entry.subject,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${entry.day} · ${entry.period}\n'
                  '${entry.className}'
                  '${entry.teacher.isNotEmpty ? ' · ${entry.teacher}' : ''}',
                ),
                isThreeLine: true,
              ),
              if (canEdit) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(ctx);
                    editTimetable(entry, idx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(ctx);
                    deleteTimetable(entry, idx);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    } else if (canEdit) {
      // Optional: quick add could open form — keep Add FAB for full form
    }
  }

  /// Short labels so grid cells stay readable.
  String _shortSubject(String name) {
    var s = name.trim();
    const map = {
      'Physical & Health Education': 'PHE',
      'Physical and Health Education': 'PHE',
      'Agricultural Science': 'Agric',
      'Basic Science': 'B.Sci',
      'Basic Technology': 'B.Tech',
      'Social Studies': 'SOS',
      'Christian Religious Studies': 'CRS',
      'Islamic Religious Studies': 'IRS',
      'Islamic Studies': 'IRS',
      'Business Studies': 'Bus.St',
      'Home Economics': 'Home Econ',
      'Computer Studies': 'ICT',
      'Information Technology': 'ICT',
      'Civic Education': 'Civic',
      'Cultural and Creative Arts': 'CCA',
      'English Language': 'English',
      'Mathematics': 'Maths',
      'Further Mathematics': 'F.Maths',
      'Literature in English': 'Lit',
      'Government': 'Govt',
      'Commerce': 'Comm',
      'Economics': 'Econs',
      'Biology': 'Bio',
      'Chemistry': 'Chem',
      'Physics': 'Phy',
      'Geography': 'Geog',
      'Accounting': 'Acct',
      'French': 'French',
      'Yoruba': 'Yoruba',
      'Igbo': 'Igbo',
      'Hausa': 'Hausa',
    };
    for (final e in map.entries) {
      if (s.toLowerCase() == e.key.toLowerCase()) return e.value;
    }
    // Soft shorten long names
    if (s.length > 18) {
      s = s.replaceAll(' and ', ' & ');
      s = s.replaceAll('Education', 'Edu');
      s = s.replaceAll('Studies', 'St.');
      s = s.replaceAll('Science', 'Sci');
      s = s.replaceAll('Technology', 'Tech');
    }
    if (s.length > 20) s = '${s.substring(0, 18)}…';
    return s;
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Colors.white24 : const Color(0xFF94A3B8);
    final headerBg = const Color(0xFF1D4ED8);
    final dayBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final breakBg = isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7);
    final emptyBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    const dayColW = 72.0;
    const periodColW = 120.0;
    const cellH = 70.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: headerBg,
        foregroundColor: Colors.white,
        title: Text(
          canEdit ? 'Timetable' : 'View Timetable',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (canEdit)
            IconButton(
              onPressed: copyTimetableDialog,
              icon: const Icon(Icons.copy_all_rounded),
              tooltip: 'Copy timetable to classes',
            ),
          IconButton(
            onPressed: loadTimetable,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: addTimetable,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            color: headerBg,
            child: DropdownButtonFormField<String>(
              key: ValueKey(
                classOptions.contains(selectedClass)
                    ? selectedClass
                    : 'All Classes',
              ),
              initialValue: classOptions.contains(selectedClass)
                  ? selectedClass
                  : 'All Classes',
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Class',
                labelStyle: const TextStyle(color: Color(0xFF1D4ED8)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.class_rounded,
                    color: Color(0xFF1D4ED8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: classOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => selectedClass = v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Icon(Icons.grid_view_rounded,
                    size: 16, color: AppColors.textSecondary(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedClass == 'All Classes'
                        ? 'Premium grid · all classes · tap a cell for details'
                        : 'Premium grid · $selectedClass · tap cell to edit',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        border: TableBorder.all(color: border, width: 1),
                        columnWidths: {
                          0: FixedColumnWidth(dayColW),
                          for (var i = 0; i < slots.length; i++)
                            i + 1: FixedColumnWidth(periodColW),
                        },
                        children: [
                          // Header: periods
                          TableRow(
                            decoration: BoxDecoration(color: headerBg),
                            children: [
                              _headerCell('DAY', bold: true),
                              ...slots.map((s) {
                                return _headerCell(
                                  s.isBreak
                                      ? s.name.toUpperCase()
                                      : '${s.name}\n${s.time}',
                                  breakStyle: s.isBreak,
                                );
                              }),
                            ],
                          ),
                          // Day rows
                          ..._days.map((day) {
                            return TableRow(
                              children: [
                                Container(
                                  height: cellH,
                                  color: dayBg,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    day.length >= 3
                                        ? day.substring(0, 3).toUpperCase()
                                        : day,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                ),
                                ...slots.map((slot) {
                                  if (slot.isBreak) {
                                    return Container(
                                      height: cellH,
                                      color: breakBg,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        slot.name.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    );
                                  }
                                  final entry = cellEntry(day, slot);
                                  return InkWell(
                                    onTap: () =>
                                        _onCellTap(day, slot, entry),
                                    child: Container(
                                      height: cellH,
                                      color: emptyBg,
                                      padding: const EdgeInsets.all(4),
                                      alignment: Alignment.center,
                                      child: entry == null
                                          ? Text(
                                              '—',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                              ),
                                            )
                                          : FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 2,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      _shortSubject(
                                                          entry.subject),
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 11,
                                                        height: 1.15,
                                                      ),
                                                    ),
                                                    if (selectedClass ==
                                                            'All Classes' &&
                                                        entry.className
                                                            .isNotEmpty)
                                                      Text(
                                                        entry.className,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          height: 1.1,
                                                          color: AppColors
                                                              .textSecondary(
                                                                  context),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                        ],
                      ), // Table
                        ), // ClipRRect
                      ), // Container
                    ), // horizontal scroll
                  ), // vertical scroll
          ), // Expanded
        ],
      ),
    );
  }

  Widget _headerCell(
    String text, {
    bool bold = false,
    bool breakStyle = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      alignment: Alignment.center,
      color: breakStyle ? const Color(0xFFFBBF24) : null,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: breakStyle ? const Color(0xFF78350F) : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: breakStyle ? 10 : 9.5,
          height: 1.15,
        ),
      ),
    );
  }
}

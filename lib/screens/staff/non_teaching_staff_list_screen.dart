import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/staff_member.dart';
import '../../services/staff_storage.dart';
import 'non_teaching_staff_form_screen.dart';
import '../../models/teacher.dart';
import '../teachers/staff_id_card_preview_screen.dart';

class NonTeachingStaffListScreen extends StatefulWidget {
  const NonTeachingStaffListScreen({super.key});

  @override
  State<NonTeachingStaffListScreen> createState() =>
      _NonTeachingStaffListScreenState();
}

class _NonTeachingStaffListScreenState
    extends State<NonTeachingStaffListScreen> {
  List<StaffMember> staff = [];
  String query = '';

  /// Map non-teaching staff into Teacher shape for the shared ID card UI.
  Teacher _asTeacher(StaffMember s) {
    final parts = s.fullName.trim().split(RegExp(r'\s+'));
    final surname = parts.isNotEmpty ? parts.first : s.fullName;
    final first = parts.length > 1 ? parts[1] : '';
    final middle = parts.length > 2 ? parts.sublist(2).join(' ') : '';
    return Teacher(
      staffId: s.id.isNotEmpty ? s.id : 'NTS',
      surname: surname,
      firstName: first,
      middleName: middle,
      gender: s.gender,
      phone: s.phone,
      email: s.email,
      address: s.address,
      qualification: s.qualification.isNotEmpty
          ? s.qualification
          : (s.otherQualifications.isNotEmpty ? s.otherQualifications : '—'),
      department: s.post.isNotEmpty ? s.post : 'Non-Teaching',
      passport: s.passport,
      employmentType: 'Full-time',
    );
  }

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    await StaffStorage.open();
    final list = StaffStorage.getAll();
    if (!mounted) return;
    setState(() {
      staff = list;
      loading = false;
    });
  }

  List<StaffMember> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return staff;
    return staff
        .where((s) =>
            s.fullName.toLowerCase().contains(q) ||
            s.post.toLowerCase().contains(q) ||
            s.phone.contains(q) ||
            s.qualification.toLowerCase().contains(q))
        .toList();
  }

  Widget _avatar(StaffMember s) {
    ImageProvider? img;
    if (s.passport.isNotEmpty) {
      try {
        final f = File(s.passport);
        if (f.existsSync()) img = FileImage(f);
      } catch (_) {}
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
      backgroundImage: img,
      child: img == null
          ? Text(
              s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F766E),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const NonTeachingStaffFormScreen(),
            ),
          );
          if (ok == true) _load();
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add staff'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Non-Teaching Staff',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${staff.length} registered · Not listed with students',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'Search name, post, phone, qualification…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text('No non-teaching staff yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final s = list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: _avatar(s),
                              title: Text(
                                s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                [
                                  s.post,
                                  if (s.qualification.isNotEmpty &&
                                      s.qualification != 'None')
                                    s.qualification,
                                  if (s.phone.isNotEmpty) s.phone,
                                ].join(' · '),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    s.active
                                        ? Icons.check_circle
                                        : Icons.pause_circle_filled,
                                    color: s.active
                                        ? const Color(0xFF059669)
                                        : Colors.grey,
                                  ),
                                  IconButton(
                                    tooltip: 'ID card',
                                    icon: const Icon(Icons.badge_outlined,
                                        color: Color(0xFF0F766E)),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              StaffIdCardPreviewScreen(
                                            teacher: _asTeacher(s),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete staff'),
                                          content:
                                              Text('Delete ${s.fullName}?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        final idx = staff.indexOf(s);
                                        if (idx >= 0) {
                                          await StaffStorage.deleteAt(idx);
                                          await _load();
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final idx = StaffStorage.indexOfId(s.id);
                                final ok = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NonTeachingStaffFormScreen(
                                      staff: s,
                                      index: idx >= 0 ? idx : null,
                                    ),
                                  ),
                                );
                                if (ok == true) _load();
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

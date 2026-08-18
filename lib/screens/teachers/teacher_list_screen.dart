import 'staff_id_card_preview_screen.dart';
import 'package:flutter/material.dart';


import '../../core/theme/app_colors.dart';

import '../../models/teacher.dart';
import '../../services/teacher_storage.dart';
import 'teacher_registration_screen.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  List<Teacher> teachers = [];
  List<Teacher> filtered = [];
  bool loading = true;
  final searchController = TextEditingController();

  
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    loadTeachers();
  }

  Future<void> loadTeachers() async {
    setState(() => loading = true);
    final data = await TeacherStorage.getTeachers();
    if (!mounted) return;
    setState(() {
      teachers = data;
      filtered = data;
      loading = false;
    });
  }

  void search(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        filtered = teachers;
      } else {
        filtered = teachers.where((t) {
          return t.fullName.toLowerCase().contains(q) ||
              t.staffId.toLowerCase().contains(q) ||
              t.department.toLowerCase().contains(q) ||
              t.phone.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> openForm({Teacher? teacher, int? index}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherRegistrationScreen(
          teacher: teacher,
          index: index,
        ),
      ),
    );
    await loadTeachers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Teachers (${filtered.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        backgroundColor: _primary,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Teacher'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: searchController,
                onChanged: search,
                decoration: InputDecoration(
                  hintText: 'Search name, staff ID, department...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No teachers found',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final teacher = filtered[index];
                          final realIndex = teachers.indexWhere(
                            (t) => t.staffId == teacher.staffId,
                          );
                          final initial = teacher.firstName.isNotEmpty
                              ? teacher.firstName[0].toUpperCase()
                              : '?';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder(context)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.035),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => openForm(
                                  teacher: teacher,
                                  index: realIndex >= 0 ? realIndex : index,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF059669),
                                              Color(0xFF34D399),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
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
                                              teacher.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              teacher.staffId,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              children: [
                                                _chip(
                                                  teacher.department.isEmpty
                                                      ? 'No dept'
                                                      : teacher.department,
                                                  const Color(0xFFECFDF5),
                                                  const Color(0xFF047857),
                                                ),
                                                if (teacher.phone.isNotEmpty)
                                                  _chip(
                                                    teacher.phone,
                                                    const Color(0xFFEFF6FF),
                                                    const Color(0xFF1D4ED8),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Staff ID Card',
                                        icon: const Icon(
                                          Icons.badge_outlined,
                                          color: Color(0xFF0D9488),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  StaffIdCardPreviewScreen(
                                                teacher: teacher,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
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

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

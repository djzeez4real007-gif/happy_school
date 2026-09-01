import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../models/subject.dart';
import '../../services/subject_storage.dart';
import 'subject_registration_screen.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  List<Subject> subjects = [];
  List<Subject> filtered = [];
  bool loading = true;
  final searchController = TextEditingController();

  
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    setState(() => loading = true);
    final data = await SubjectStorage.getSubjects();
    // Unique by subject code (no class-based duplicates)
    final seen = <String>{};
    final unique = <Subject>[];
    for (final s in data) {
      final code = s.subjectCode.trim().toLowerCase();
      final key = code.isNotEmpty ? code : s.subjectName.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      unique.add(s);
    }
    unique.sort((a, b) => a.subjectName.toLowerCase().compareTo(b.subjectName.toLowerCase()));
    if (!mounted) return;
    setState(() {
      subjects = unique;
      filtered = unique;
      loading = false;
    });
  }

  void search(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        filtered = subjects;
      } else {
        filtered = subjects.where((s) {
          return s.subjectName.toLowerCase().contains(q) ||
              s.subjectCode.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> openForm({Subject? subject, int? index}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectRegistrationScreen(
          subject: subject,
          index: index,
        ),
      ),
    );
    await loadSubjects();
  }

  Future<void> confirmDelete(Subject subject, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Subject'),
        content: Text('Delete ${subject.subjectName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await SubjectStorage.deleteSubjectByCode(subject.subjectCode);
      await loadSubjects();
    }
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
          'Subjects (${filtered.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subject'),
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
                  hintText: 'Search subject, code, class...',
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
                            Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No subjects found',
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
                          final subject = filtered[index];
                          // Prefer code-based edit/delete (list is de-duplicated)
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
                                          Color(0xFF7C3AED),
                                          Color(0xFFA78BFA),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject.subjectName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _chip(
                                              subject.subjectCode,
                                              const Color(0xFFF5F3FF),
                                              const Color(0xFF6D28D9),
                                            ),
                                            _chip(
                                              ''.isEmpty
                                                  ? 'All classes'
                                                  : '',
                                              const Color(0xFFEFF6FF),
                                              const Color(0xFF1D4ED8),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        await openForm(subject: subject);
                                      } else if (value == 'delete') {
                                        await confirmDelete(subject, 0);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
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

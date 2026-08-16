import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

import '../../models/announcement.dart';
import '../../services/announcement_storage.dart';
import 'announcement_form_screen.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  List<Announcement> announcements = [];
  bool loading = true;

  
  static const Color _primary = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    setState(() => loading = true);
    final data = await AnnouncementStorage.getAnnouncements();

    data.sort((a, b) {
      if (a.pinned == b.pinned) return 0;
      return a.pinned ? -1 : 1;
    });

    if (!mounted) return;
    setState(() {
      announcements = data;
      loading = false;
    });
  }

  Future<void> deleteAnnouncement(int index) async {
    await AnnouncementStorage.deleteAnnouncement(index);
    if (!mounted) return;
    await loadAnnouncements();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement deleted')),
    );
  }

  Future<void> openNewAnnouncement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnnouncementFormScreen()),
    );
    if (!mounted) return;
    await loadAnnouncements();
  }

  Future<void> editAnnouncement(Announcement announcement, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnnouncementFormScreen(announcement: announcement, index: index),
      ),
    );
    if (!mounted) return;
    await loadAnnouncements();
  }

  Future<void> confirmDelete(Announcement announcement, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete'),
          content: const Text('Delete this announcement?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed == true) {
      await deleteAnnouncement(index);
    }
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
          'Announcements (${announcements.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openNewAnnouncement,
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No announcements yet',
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
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    final pinned = announcement.pinned;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: pinned
                              ? const Color(0xFFFECACA)
                              : Colors.grey.shade200,
                        ),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: pinned
                                      ? [
                                          const Color(0xFFDC2626),
                                          const Color(0xFFF87171),
                                        ]
                                      : [
                                          const Color(0xFF1D4ED8),
                                          const Color(0xFF60A5FA),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                pinned
                                    ? Icons.push_pin_rounded
                                    : Icons.campaign_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          announcement.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (pinned)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'PINNED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFB91C1C),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    announcement.message,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    announcement.date,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await editAnnouncement(announcement, index);
                                }
                                if (value == 'delete') {
                                  await confirmDelete(announcement, index);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

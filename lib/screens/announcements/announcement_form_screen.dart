import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../core/widgets/premium_form.dart';
import '../../models/announcement.dart';
import '../../services/audit_log_storage.dart';
import '../../services/announcement_storage.dart';

class AnnouncementFormScreen extends StatefulWidget {
  final Announcement? announcement;
  final int? index;

  const AnnouncementFormScreen({super.key, this.announcement, this.index});

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  bool pinned = false;
  bool saving = false;

  bool get isEdit => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      titleController.text = widget.announcement!.title;
      messageController.text = widget.announcement!.message;
      pinned = widget.announcement!.pinned;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final item = Announcement(
      id: widget.announcement?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      message: messageController.text.trim(),
      date: widget.announcement?.date ??
          DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      pinned: pinned,
    );
    try {
      if (isEdit) {
        await AnnouncementStorage.updateAnnouncement(widget.index!, item);
      } else {
        await AnnouncementStorage.addAnnouncement(item);
      }
      if (!mounted) return;
      await AuditLogStorage.log(
        action: 'announcement_saved',
        module: 'announcements',
        description: 'Saved announcement',
      );
      PremiumFeedback.success(
        context,
        title: isEdit ? 'Announcement updated' : 'Announcement published',
        subtitle: item.title,
        icon: Icons.campaign_rounded,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      PremiumFeedback.error(context, title: 'Could not save', subtitle: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        leading: AppBack.leading(context),
        title: Text(isEdit ? 'Edit Announcement' : 'New Announcement'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            PremiumForm.header(
              context,
              title: isEdit ? 'Edit Announcement' : 'New Announcement',
              subtitle: 'Visible on the dashboard ticker',
              icon: Icons.campaign_rounded,
              gradient: const [Color(0xFFB45309), Color(0xFFF59E0B)],
            ),
            const SizedBox(height: 16),
            PremiumForm.card(
              context,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter message' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pin to top'),
                  subtitle: const Text('Pinned items appear first'),
                  value: pinned,
                  onChanged: (v) => setState(() => pinned = v),
                ),
                const SizedBox(height: 16),
                PremiumForm.primaryButton(
                  label: isEdit ? 'UPDATE' : 'PUBLISH',
                  onPressed: _save,
                  loading: saving,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

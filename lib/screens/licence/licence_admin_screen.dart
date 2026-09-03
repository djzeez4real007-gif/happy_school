import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/licence_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/school_licence.dart';
import 'pricing_editor_screen.dart';

class LicenceAdminScreen extends StatefulWidget {
  const LicenceAdminScreen({super.key});

  @override
  State<LicenceAdminScreen> createState() => _LicenceAdminScreenState();
}

class _LicenceAdminScreenState extends State<LicenceAdminScreen> {
  late LicencePlan plan;
  late TextEditingController maxStudents;
  late TextEditingController notes;
  late TextEditingController phone;
  late TextEditingController whatsapp;
  late TextEditingController price;
  late TextEditingController licenceKey;
  DateTime? expiresAt;
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final l = LicenceController.instance.licence;
    plan = l.plan;
    maxStudents = TextEditingController(text: '${l.maxStudents}');
    notes = TextEditingController(text: l.notes);
    phone = TextEditingController(text: l.contactPhone);
    whatsapp = TextEditingController(text: l.contactWhatsapp);
    price = TextEditingController(
      text: l.priceAmount == null ? '' : l.priceAmount!.toStringAsFixed(0),
    );
    licenceKey = TextEditingController(text: l.licenceKey);
    expiresAt = l.expiresAt;
    active = l.active;
  }

  @override
  void dispose() {
    maxStudents.dispose();
    notes.dispose();
    phone.dispose();
    whatsapp.dispose();
    price.dispose();
    licenceKey.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: expiresAt ?? now.add(const Duration(days: 90)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => expiresAt = picked);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final licence = SchoolLicence(
        plan: plan,
        expiresAt: plan == LicencePlan.oneTime ? null : expiresAt,
        maxStudents: int.tryParse(maxStudents.text.trim()) ?? 150,
        active: active,
        notes: notes.text.trim(),
        contactPhone: phone.text.trim(),
        contactWhatsapp: whatsapp.text.trim(),
        priceAmount: double.tryParse(price.text.trim()),
        currency: 'NGN',
        activatedAt:
            LicenceController.instance.licence.activatedAt ?? DateTime.now(),
        licenceKey: licenceKey.text.trim(),
      );
      await LicenceController.instance.save(licence);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF059669),
          content: Text('Licence saved'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = LicenceController.instance.licence;
    final df = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('Licence & billing'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: Text(
              saving ? 'Saving…' : 'Save',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _statusCard(l, df),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PricingEditorScreen()),
              );
            },
            icon: const Icon(Icons.price_change_rounded),
            label: const Text('Edit plans & prices (shown to schools)'),
          ),
          const SizedBox(height: 16),
          Text(
            'Plan settings',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<LicencePlan>(
            value: plan,
            decoration: InputDecoration(
              labelText: 'Plan type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
            items: LicencePlan.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => plan = v);
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: active,
            title: const Text('Licence active'),
            subtitle: const Text('Turn off to lock the school installation'),
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => active = v),
          ),
          const SizedBox(height: 8),
          if (plan != LicencePlan.oneTime) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry date'),
              subtitle: Text(
                expiresAt == null ? 'Not set' : df.format(expiresAt!),
              ),
              trailing: OutlinedButton.icon(
                onPressed: _pickExpiry,
                icon: const Icon(Icons.event),
                label: const Text('Pick date'),
              ),
            ),
          ] else
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('One-time licence'),
              subtitle: Text('No expiry (optional maintenance later)'),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: maxStudents,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max students',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Agreed amount (NGN)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: licenceKey,
            decoration: InputDecoration(
              labelText: 'Licence key (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Support contact (shown on pricing)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phone,
            decoration: InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: whatsapp,
            decoration: InputDecoration(
              labelText: 'WhatsApp',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.save_rounded),
            label: Text(saving ? 'Saving…' : 'Save licence'),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(SchoolLicence l, DateFormat df) {
    final color = l.isExpired
        ? const Color(0xFFDC2626)
        : l.isExpiringSoon
            ? const Color(0xFFD97706)
            : const Color(0xFF059669);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.statusLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.plan.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.plan == LicencePlan.oneTime
                ? 'No expiry · Max ${l.maxStudents} students'
                : 'Expires: ${l.expiresAt == null ? '—' : df.format(l.expiresAt!)} · Max ${l.maxStudents} students',
            style: const TextStyle(color: Colors.white),
          ),
          if (l.daysRemaining != null && !l.isExpired)
            Text(
              '${l.daysRemaining} day(s) remaining',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

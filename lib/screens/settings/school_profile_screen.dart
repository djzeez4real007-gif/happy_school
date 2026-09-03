import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/school_profile_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/school_profile.dart';

class SchoolProfileScreen extends StatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  State<SchoolProfileScreen> createState() => _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends State<SchoolProfileScreen> {
  final _name = TextEditingController();
  final _motto = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  String logoPath = '';
  String logoBase64 = '';
  Color primary = const Color(0xFF1D4ED8);
  Color accent = const Color(0xFF3B82F6);
  bool saving = false;

  static const _presets = <Color>[
    // Blues
    Color(0xFF1D4ED8),
    Color(0xFF2563EB),
    Color(0xFF3B82F6),
    Color(0xFF1E3A8A),
    Color(0xFF0EA5E9),
    Color(0xFF0284C7),
    Color(0xFF0369A1),
    // Teals / cyan
    Color(0xFF0F766E),
    Color(0xFF0D9488),
    Color(0xFF14B8A6),
    Color(0xFF0E7490),
    Color(0xFF0891B2),
    Color(0xFF06B6D4),
    // Greens
    Color(0xFF047857),
    Color(0xFF059669),
    Color(0xFF10B981),
    Color(0xFF16A34A),
    Color(0xFF15803D),
    Color(0xFF166534),
    // Purples
    Color(0xFF7C3AED),
    Color(0xFF8B5CF6),
    Color(0xFF6D28D9),
    Color(0xFF5B21B6),
    Color(0xFFA855F7),
    Color(0xFF9333EA),
    // Pinks / magenta
    Color(0xFFDB2777),
    Color(0xFFEC4899),
    Color(0xFFBE185D),
    Color(0xFF9D174D),
    // Reds
    Color(0xFFBE123C),
    Color(0xFFDC2626),
    Color(0xFFEF4444),
    Color(0xFFB91C1C),
    Color(0xFF991B1B),
    // Orange / amber / gold
    Color(0xFFB45309),
    Color(0xFFD97706),
    Color(0xFFF59E0B),
    Color(0xFFEA580C),
    Color(0xFFF97316),
    Color(0xFFCA8A04),
    // Neutrals / dark
    Color(0xFF0F172A),
    Color(0xFF1E293B),
    Color(0xFF334155),
    Color(0xFF475569),
    Color(0xFF111827),
    Color(0xFF374151),
  ];

  @override
  void initState() {
    super.initState();
    final p = SchoolProfileController.instance.profile;
    _name.text = p.name;
    _motto.text = p.motto;
    _address.text = p.address;
    _phone.text = p.phone;
    _email.text = p.email;
    logoPath = p.logoPath;
    logoBase64 = p.logoBase64;
    primary = p.primaryColor;
    accent = p.accentColor;
  }

  @override
  void dispose() {
    _name.dispose();
    _motto.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      logoBase64 = base64Encode(bytes);
      logoPath = picked.path;
    });
  }

  Future<void> _pickColor({required bool isPrimary}) async {
    Color temp = isPrimary ? primary : accent;
    final hexCtrl = TextEditingController(
      text: temp.toARGB32().toRadixString(16).substring(2).toUpperCase(),
    );
    final result = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(isPrimary ? 'Primary colour' : 'Accent colour'),
              content: SizedBox(
                width: 340,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tap a colour',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presets.map((c) {
                          final selected = c.toARGB32() == temp.toARGB32();
                          return InkWell(
                            onTap: () {
                              setLocal(() {
                                temp = c;
                                hexCtrl.text = c
                                    .toARGB32()
                                    .toRadixString(16)
                                    .substring(2)
                                    .toUpperCase();
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Colors.black
                                      : Colors.white,
                                  width: selected ? 3 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.35),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Or enter hex (e.g. 1D4ED8)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: hexCtrl,
                        maxLength: 8,
                        decoration: InputDecoration(
                          prefixText: '# ',
                          counterText: '',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Apply hex',
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () {
                              final raw = hexCtrl.text.trim().replaceAll('#', '');
                              final v = int.tryParse(raw, radix: 16);
                              if (v == null) return;
                              final color = Color(raw.length <= 6 ? (0xFF000000 | v) : v);
                              setLocal(() => temp = color);
                            },
                          ),
                        ),
                        onSubmitted: (_) {
                          final raw = hexCtrl.text.trim().replaceAll('#', '');
                          final v = int.tryParse(raw, radix: 16);
                          if (v == null) return;
                          final color = Color(raw.length <= 6 ? (0xFF000000 | v) : v);
                          setLocal(() => temp = color);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Preview'),
                          const SizedBox(width: 10),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: temp,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, temp),
                  child: const Text('Use colour'),
                ),
              ],
            );
          },
        );
      },
    );
    hexCtrl.dispose();
    if (result != null) {
      setState(() {
        if (isPrimary) {
          primary = result;
        } else {
          accent = result;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final profile = SchoolProfile(
        name: _name.text.trim().isEmpty ? 'Happy School' : _name.text.trim(),
        motto: _motto.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        logoPath: logoPath,
        logoBase64: logoBase64,
        primaryColorValue: primary.toARGB32(),
        accentColorValue: accent.toARGB32(),
      );
      await SchoolProfileController.instance.save(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF059669),
          content: Text('School profile saved — applies across the app'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Could not save: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _logoPreview() {
    final bytes = logoBase64.isNotEmpty
        ? (() {
            try {
              return base64Decode(logoBase64);
            } catch (_) {
              return null;
            }
          })()
        : null;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: primary, width: 3),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 12,
          ),
        ],
        image: bytes != null
            ? DecorationImage(
                image: MemoryImage(Uint8List.fromList(bytes)),
                fit: BoxFit.cover,
              )
            : const DecorationImage(
                image: AssetImage('assets/images/school_logo.png'),
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: const Text('School profile'),
        backgroundColor: primary,
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
          Center(
            child: Column(
              children: [
                _logoPreview(),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Change logo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'School identity',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 10),
          _field(_name, 'School name', Icons.school_outlined),
          _field(_motto, 'Motto', Icons.format_quote_rounded),
          _field(_address, 'Address', Icons.location_on_outlined, maxLines: 2),
          _field(_phone, 'Phone', Icons.phone_outlined),
          _field(_email, 'Email', Icons.email_outlined),
          const SizedBox(height: 20),
          Text(
            'Theme colours',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Used for headers, buttons and accents across the app.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          _colorRow(
            label: 'Primary',
            color: primary,
            onTap: () => _pickColor(isPrimary: true),
          ),
          const SizedBox(height: 10),
          _colorRow(
            label: 'Accent',
            color: accent,
            onTap: () => _pickColor(isPrimary: false),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.save_rounded),
            label: Text(saving ? 'Saving…' : 'Save school profile'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _colorRow({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

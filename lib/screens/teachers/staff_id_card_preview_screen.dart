import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';
import '../../core/school_profile_controller.dart';

import '../../core/widgets/premium_feedback.dart';
import '../../models/teacher.dart';
import '../../services/staff_id_card_pdf_service.dart';

/// Premium on-screen preview of a staff ID card before printing.
class StaffIdCardPreviewScreen extends StatelessWidget {
  final Teacher teacher;

  const StaffIdCardPreviewScreen({super.key, required this.teacher});

  Future<void> _print(BuildContext context) async {
    try {
      await StaffIdCardPdfService.generate(teacher);
      if (!context.mounted) return;
      PremiumFeedback.success(
        context,
        title: 'Staff ID ready',
        subtitle: 'Print or share from the system dialog',
        icon: Icons.badge_rounded,
      );
    } catch (e) {
      if (!context.mounted) return;
      PremiumFeedback.error(
        context,
        title: 'Could not generate ID card',
        subtitle: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = teacher.passport.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF042F2E),
      appBar: AppBar(
        leading: AppBack.leading(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Staff ID Card',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      const Text(
                        'Preview',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AspectRatio(
                        aspectRatio: 1.6,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D9488)
                                    .withValues(alpha: 0.5),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF134E4A),
                                Color(0xFF0F766E),
                                Color(0xFF0D9488),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF134E4A),
                                          Color(0xFF0D9488),
                                        ],
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.school_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                SchoolProfileController.instance.name.toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                  letterSpacing: 0.6,
                                                ),
                                              ),
                                              Text(
                                                'Staff Identification Card',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.18),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.white24,
                                            ),
                                          ),
                                          child: const Text(
                                            'STAFF ID',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 12, 14, 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 88,
                                            height: 108,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF0D9488),
                                                width: 2,
                                              ),
                                              color: const Color(0xFFECFDF5),
                                              image: hasPhoto
                                                  ? DecorationImage(
                                                      image: FileImage(
                                                        File(teacher.passport),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: hasPhoto
                                                ? null
                                                : Center(
                                                    child: Text(
                                                      teacher.firstName
                                                              .isNotEmpty
                                                          ? teacher
                                                              .firstName[0]
                                                              .toUpperCase()
                                                          : 'T',
                                                      style: const TextStyle(
                                                        fontSize: 36,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            Color(0xFF0F766E),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  teacher.fullName,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15,
                                                    color: Color(0xFF042F2E),
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                _infoRow(
                                                  Icons.badge_outlined,
                                                  'Staff ID',
                                                  teacher.staffId,
                                                ),
                                                _infoRow(
                                                  Icons.apartment_outlined,
                                                  'Department',
                                                  teacher.department.isEmpty
                                                      ? '—'
                                                      : teacher.department,
                                                ),
                                                _infoRow(
                                                  Icons.school_outlined,
                                                  'Qualification',
                                                  teacher.qualification.isEmpty
                                                      ? '—'
                                                      : teacher.qualification,
                                                ),
                                                _infoRow(
                                                  Icons.phone_outlined,
                                                  'Phone',
                                                  teacher.phone.isEmpty
                                                      ? '—'
                                                      : teacher.phone,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    color: const Color(0xFFF0FDFA),
                                    child: Text(
                                      'Authorized staff identification · ${SchoolProfileController.instance.name}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF0F766E),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        teacher.staffId,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _print(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text(
                        'Print / Share PDF',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF042F2E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

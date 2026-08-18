import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_feedback.dart';
import '../../models/student.dart';
import '../../models/student_class.dart';
import '../../services/id_card_pdf_service.dart';

/// Premium on-screen preview of a student ID card before printing.
class StudentIdCardPreviewScreen extends StatelessWidget {
  final Student student;
  final StudentClass? studentClass;
  final String session;

  const StudentIdCardPreviewScreen({
    super.key,
    required this.student,
    this.studentClass,
    this.session = '2026/2027',
  });

  Future<void> _print(BuildContext context) async {
    try {
      await IdCardPdfService.generateStudentIdCard(
        student: student,
        studentClass: studentClass,
        session: session,
      );
      if (!context.mounted) return;
      PremiumFeedback.success(
        context,
        title: 'ID Card ready',
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
    final className = studentClass?.className ?? 'Not assigned';
    final hasPhoto = student.passport.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Student ID Card',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

                      // ===== PREMIUM CARD =====
                      AspectRatio(
                        aspectRatio: 1.6,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1D4ED8)
                                    .withValues(alpha: 0.45),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0F172A),
                                Color(0xFF1E3A8A),
                                Color(0xFF1D4ED8),
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
                                  // Top brand bar
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF0F172A),
                                          Color(0xFF1D4ED8),
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
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'HAPPY SCHOOL',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                  letterSpacing: 0.6,
                                                ),
                                              ),
                                              Text(
                                                'Excellence · Integrity · Knowledge',
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
                                            'STUDENT ID',
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

                                  // Body
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 12, 14, 10),
                                      child: Row(
                                        children: [
                                          // Photo
                                          Container(
                                            width: 88,
                                            height: 108,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF1D4ED8),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF1D4ED8)
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                              color: const Color(0xFFEFF6FF),
                                              image: hasPhoto
                                                  ? DecorationImage(
                                                      image: FileImage(
                                                        File(student.passport),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: hasPhoto
                                                ? null
                                                : Center(
                                                    child: Text(
                                                      student.firstName
                                                              .isNotEmpty
                                                          ? student
                                                              .firstName[0]
                                                              .toUpperCase()
                                                          : 'S',
                                                      style: const TextStyle(
                                                        fontSize: 36,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color:
                                                            Color(0xFF1D4ED8),
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
                                                  student.fullName,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 15,
                                                    color: Color(0xFF0F172A),
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                _infoRow(
                                                  Icons.badge_outlined,
                                                  'Admission',
                                                  student.admissionNo,
                                                ),
                                                _infoRow(
                                                  Icons.class_outlined,
                                                  'Class',
                                                  className,
                                                ),
                                                _infoRow(
                                                  Icons.calendar_month_outlined,
                                                  'Session',
                                                  session,
                                                ),
                                                _infoRow(
                                                  Icons.person_outline,
                                                  'Gender',
                                                  student.gender.isEmpty
                                                      ? '—'
                                                      : student.gender,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Footer strip
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    color: const Color(0xFFF1F5F9),
                                    child: const Text(
                                      'This card remains the property of Happy School',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
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
                        student.admissionNo,
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

            // Actions
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
                        backgroundColor: const Color(0xFF1D4ED8),
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
                      color: Color(0xFF0F172A),
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

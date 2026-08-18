import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:open_filex/open_filex.dart';

import '../../models/report_card.dart';
import '../../services/report_card_pdf_service.dart';

class ReportCardScreen extends StatelessWidget {
  final ReportCard reportCard;

  const ReportCardScreen({super.key, required this.reportCard});

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryBlue = Color(0xFF1769E0);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color background = Color(0xFFF5F7FB);

  // ==========================================================
  // GRADE COLOR
  // ==========================================================

  Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A1':
        return Colors.green.shade700;

      case 'B2':
      case 'B3':
        return Colors.blue.shade700;

      case 'C4':
      case 'C5':
      case 'C6':
        return Colors.orange.shade700;

      case 'D7':
      case 'E8':
        return Colors.deepOrange.shade700;

      default:
        return Colors.red.shade700;
    }
  }

  // ==========================================================
  // POSITION TEXT
  // ==========================================================

  String positionText(int position) {
    if (position <= 0) {
      return '-';
    }

    if (position % 100 >= 11 && position % 100 <= 13) {
      return '${position}th';
    }

    switch (position % 10) {
      case 1:
        return '${position}st';

      case 2:
        return '${position}nd';

      case 3:
        return '${position}rd';

      default:
        return '${position}th';
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
        title: const Text(
          'Student Report Card',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Generate PDF',
            onPressed: () => generatePdf(context),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildSchoolHeader(),

              const SizedBox(height: 16),

              buildStudentInformation(),

              const SizedBox(height: 16),

              buildPerformanceSummary(),

              const SizedBox(height: 16),

              buildResultsTable(),

              const SizedBox(height: 16),

              buildAcademicSummary(),

              const SizedBox(height: 16),

              buildRemarksCard(),

              const SizedBox(height: 20),

              buildActionButtons(context),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  'Happy School Management System',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SCHOOL HEADER
  // ==========================================================

  Widget buildSchoolHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkBlue, primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.20),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'HAPPY SCHOOL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'STUDENT REPORT CARD',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '${reportCard.session} • ${reportCard.term}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STUDENT INFORMATION
  // ==========================================================

  Widget buildStudentInformation() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.person_outline,
            title: 'Student Information',
            subtitle: 'Academic identification details',
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(Icons.person, color: primaryBlue, size: 30),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportCard.studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      reportCard.admissionNo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.school_outlined,
                  label: 'Class',
                  value: reportCard.className,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _infoItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Session',
                  value: reportCard.session,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _infoItem(
            icon: Icons.event_note_outlined,
            label: 'Term',
            value: reportCard.term,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PERFORMANCE SUMMARY
  // ==========================================================

  Widget buildPerformanceSummary() {
    final color = gradeColor(reportCard.overallGrade);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.analytics_outlined,
            title: 'Performance Summary',
            subtitle: 'Overall academic performance',
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.score_outlined,
                  label: 'Total',
                  value: reportCard.total.toStringAsFixed(1),
                  color: Colors.blue,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _statCard(
                  icon: Icons.trending_up,
                  label: 'Average',
                  value: reportCard.average.toStringAsFixed(1),
                  color: Colors.purple,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _statCard(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Grade',
                  value: reportCard.overallGrade,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: color, size: 24),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Remark',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        reportCard.overallRemark,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RESULTS TABLE
  // ==========================================================

  Widget buildResultsTable() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: _sectionTitle(
              icon: Icons.table_chart_outlined,
              title: 'Subject Results',
              subtitle: '${reportCard.subjects.length} subjects recorded',
            ),
          ),

          const Divider(height: 1),

          if (reportCard.subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Text(
                  'No subject results available.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 52,
                dataRowMinHeight: 58,
                dataRowMaxHeight: 70,
                columnSpacing: 18,
                horizontalMargin: 16,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(
                    label: Text(
                      'SUBJECT',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      'CA1',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      'CA2',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      'EXAM',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      'TOTAL',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      'GRADE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      'REMARK',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                rows: reportCard.subjects.map((subject) {
                  final color = gradeColor(subject.grade);

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            subject.subjectName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        Center(child: Text(subject.ca1.toStringAsFixed(0))),
                      ),

                      DataCell(
                        Center(child: Text(subject.ca2.toStringAsFixed(0))),
                      ),

                      DataCell(
                        Center(child: Text(subject.exam.toStringAsFixed(0))),
                      ),

                      DataCell(
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: subject.total >= 40
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subject.total.toStringAsFixed(0),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: subject.total >= 40
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject.grade,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      DataCell(
                        SizedBox(
                          width: 90,
                          child: Text(
                            subject.remark,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACADEMIC SUMMARY
  // ==========================================================

  Widget buildAcademicSummary() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.school_outlined,
            title: 'Academic Summary',
            subtitle: 'Class standing and attendance',
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _detailTile(
                  icon: Icons.leaderboard_outlined,
                  label: 'Class Position',
                  value: positionText(reportCard.position),
                  color: Colors.indigo,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _detailTile(
                  icon: Icons.fact_check_outlined,
                  label: 'Attendance',
                  value:
                      '${reportCard.attendancePresent}/${reportCard.attendanceTotal}',
                  color: Colors.teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (reportCard.promoted == true) ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (reportCard.promoted == true) ? Colors.green.shade100
                    : Colors.red.shade100,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  reportCard.promoted == null
                      ? Icons.remove_circle_outline
                      : (reportCard.promoted == true
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined),
                  color: (reportCard.promoted == true)
                              ? Colors.green.shade700
                              : (reportCard.promoted == false)
                                  ? Colors.red.shade700
                                  : Colors.grey.shade600,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promotion Status',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        reportCard.promotionLabel,
                        style: TextStyle(
                          color: (reportCard.promoted == true)
                              ? Colors.green.shade700
                              : (reportCard.promoted == false)
                                  ? Colors.red.shade700
                                  : Colors.grey.shade600,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REMARKS
  // ==========================================================

  Widget buildRemarksCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.rate_review_outlined,
            title: 'Remarks',
            subtitle: 'Comments from school management',
          ),

          const SizedBox(height: 18),

          _remarkBox(
            title: "Class Teacher's Remark",
            icon: Icons.person_outline,
            text: reportCard.classTeacherRemark,
            color: Colors.blue,
          ),

          const SizedBox(height: 12),

          _remarkBox(
            title: "Principal's Remark",
            icon: Icons.admin_panel_settings_outlined,
            text: reportCard.principalRemark,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTION BUTTONS
  // ==========================================================

  Widget buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => generatePdf(context),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text(
                'Generate PDF',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                // Sharing will be added later.
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text(
                'Share',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: BorderSide(color: primaryBlue.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // GENERATE PDF
  // ==========================================================

  Future<void> generatePdf(BuildContext context) async {
    try {
      final file = await ReportCardPdfService.generatePdf(reportCard);

      await OpenFilex.open(file.path);
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to generate report card PDF: $e')),
      );
    }
  }

  // ==========================================================
  // GENERIC CARD
  // ==========================================================

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryBlue, size: 21),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // INFO ITEM
  // ==========================================================

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STAT CARD
  // ==========================================================

  // IMPORTANT:
  // This accepts Color, NOT MaterialColor.
  //
  // gradeColor() returns Color, and therefore the previous
  // MaterialColor requirement caused the analyzer error.

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 21, color: color),

          const SizedBox(height: 7),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DETAIL TILE
  // ==========================================================

  Widget _detailTile({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 23),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.shade700.withValues(alpha: 0.70),
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.shade700,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REMARK BOX
  // ==========================================================

  Widget _remarkBox({
    required String title,
    required IconData icon,
    required String text,
    required MaterialColor color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color.shade700),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  text.trim().isEmpty ? 'No remark provided.' : text,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
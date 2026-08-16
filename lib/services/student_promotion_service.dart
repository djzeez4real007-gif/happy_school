import '../models/student_class.dart';
import '../models/student_subject.dart';
import '../models/report_card.dart';

import 'student_class_storage.dart';
import 'student_subject_storage.dart';
import 'class_subject_storage.dart';
import 'report_card_storage.dart';

class StudentPromotionService {
  // ==========================================================
  // AUTOMATIC PROMOTION RULE
  // ==========================================================

  static const double automaticPromotionThreshold = 40.0;

  // ==========================================================
  // CHECK ELIGIBILITY
  // ==========================================================

  static bool isEligible(double average) {
    return average >= automaticPromotionThreshold;
  }

  // ==========================================================
  // GET STUDENT AVERAGE
  // ==========================================================
  //
  // Looks inside ReportCardStorage for the student's report
  // card for the specified session and term.
  //
  // Returns 0.0 if no report card exists.
  //
  // ==========================================================

  static Future<double> getStudentAverage({
    required String admissionNo,
    required String session,
    required String term,
  }) async {
    final reportCards = await ReportCardStorage.getReportCards();

    final targetAdmission = admissionNo.trim().toLowerCase();

    final targetSession = session.trim().toLowerCase();

    final targetTerm = term.trim().toLowerCase();

    ReportCard? matchingReport;

    for (final report in reportCards) {
      final sameAdmission =
          report.admissionNo.trim().toLowerCase() == targetAdmission;

      final sameSession = report.session.trim().toLowerCase() == targetSession;

      final sameTerm = report.term.trim().toLowerCase() == targetTerm;

      if (sameAdmission && sameSession && sameTerm) {
        matchingReport = report;
        break;
      }
    }

    if (matchingReport == null) {
      return 0.0;
    }

    return matchingReport.average;
  }

  // ==========================================================
  // PROMOTE ONE STUDENT
  // ==========================================================

  static Future<void> promoteStudent({
    required StudentClass currentAssignment,
    required String newClassName,
    required String newSession,
  }) async {
    final admissionNo = currentAssignment.admissionNo.trim();

    final studentName = currentAssignment.studentName;

    final targetClass = newClassName.trim();

    final targetSession = newSession.trim();

    if (admissionNo.isEmpty || targetClass.isEmpty || targetSession.isEmpty) {
      return;
    }

    // --------------------------------------------------------
    // Check whether the student already has the target
    // session/class assignment.
    // --------------------------------------------------------

    final existingAssignment = await StudentClassStorage.getStudentForPeriod(
      admissionNo: admissionNo,
      session: targetSession,
      term: '',
    );

    if (existingAssignment != null &&
        existingAssignment.className.trim().toLowerCase() ==
            targetClass.toLowerCase()) {
      // Already promoted to this class/session.
      return;
    }

    // --------------------------------------------------------
    // Get subjects belonging to the NEW CLASS.
    // --------------------------------------------------------

    final newClassSubjects = await ClassSubjectStorage.getClassSubjects(
      targetClass,
    );

    // --------------------------------------------------------
    // IMPORTANT:
    //
    // We DO NOT delete the old StudentClass record.
    //
    // Example:
    //
    // 2026/2027 -> JSS 1
    // 2027/2028 -> JSS 2
    //
    // Both records remain.
    // --------------------------------------------------------

    final newAssignment = StudentClass(
      admissionNo: admissionNo,
      studentName: studentName,
      className: targetClass,
      session: targetSession,
      term: '',
    );

    await StudentClassStorage.assignStudent(newAssignment);

    // --------------------------------------------------------
    // Only remove subjects belonging to the NEW session.
    //
    // Historical subjects remain untouched.
    // --------------------------------------------------------

    await StudentSubjectStorage.deleteSubjectsForPeriod(
      admissionNo: admissionNo,
      session: targetSession,
      term: 'First Term',
    );

    // --------------------------------------------------------
    // Assign the subjects of the new class.
    // --------------------------------------------------------

    for (final subject in newClassSubjects) {
      await StudentSubjectStorage.assignSubject(
        StudentSubject(
          admissionNo: admissionNo,
          studentName: studentName,
          className: targetClass,
          subjectCode: subject.subjectCode,
          subjectName: subject.subjectName,
          session: targetSession,
          term: 'First Term',
        ),
      );
    }
  }

  // ==========================================================
  // PROMOTE MULTIPLE STUDENTS
  // ==========================================================

  static Future<int> promoteStudents({
    required List<StudentClass> students,
    required String newClassName,
    required String newSession,
  }) async {
    int promotedCount = 0;

    for (final student in students) {
      try {
        await promoteStudent(
          currentAssignment: student,
          newClassName: newClassName,
          newSession: newSession,
        );

        promotedCount++;
      } catch (_) {
        // Continue with the next student if one student fails.
      }
    }

    return promotedCount;
  }
}

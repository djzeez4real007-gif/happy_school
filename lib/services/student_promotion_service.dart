import '../models/student_class.dart';
import '../models/student_subject.dart';
import '../models/report_card.dart';

import 'student_class_storage.dart';
import 'student_subject_storage.dart';
import 'class_subject_storage.dart';
import 'report_card_storage.dart';
import 'result_storage.dart';
import 'student_promotion_storage.dart';
import '../models/student_promotion.dart';

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
    final targetAdmission = admissionNo.trim().toLowerCase();
    final targetSession = session.trim().toLowerCase();
    final targetTerm = term.trim().toLowerCase();

    // 1) Prefer live results (result entry) for this session + term.
    //    This is what teachers enter before report cards are generated.
    final allResults = await ResultStorage.getResults();
    final studentResults = allResults.where((r) {
      return r.admissionNo.trim().toLowerCase() == targetAdmission &&
          r.session.trim().toLowerCase() == targetSession &&
          r.term.trim().toLowerCase() == targetTerm;
    }).toList();

    if (studentResults.isNotEmpty) {
      double sum = 0;
      for (final r in studentResults) {
        sum += r.total; // ca1 + ca2 + exam
      }
      return sum / studentResults.length;
    }

    // 2) Fallback: report card average (if generated).
    final reportCards = await ReportCardStorage.getReportCards();
    for (final report in reportCards) {
      final sameAdmission =
          report.admissionNo.trim().toLowerCase() == targetAdmission;
      final sameSession =
          report.session.trim().toLowerCase() == targetSession;
      final sameTerm = report.term.trim().toLowerCase() == targetTerm;
      if (sameAdmission && sameSession && sameTerm) {
        return report.average;
      }
    }

    return 0.0;
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

    // If already on this class in target session, still ensure record is fresh.
    // (Do not return early without writing — older bugs left next session empty.)

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

    final isGraduated = targetClass.trim().toLowerCase() == 'graduated' ||
        targetClass.trim().toLowerCase() == 'left' ||
        targetClass.trim().toLowerCase() == 'withdrawn';

    // Graduated students do not get subject assignments for the next session.
    if (isGraduated) {
      return;
    }

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


  // ==========================================================
  // REPEAT ONE STUDENT (same class, next session)
  // ==========================================================


  // ==========================================================
  // LEFT SCHOOL (completed a class, did not return next session)
  // ==========================================================

  static Future<void> markStudentLeft({
    required StudentClass currentAssignment,
    required String newSession,
    double average = 0,
  }) async {
    final admissionNo = currentAssignment.admissionNo.trim();
    final studentName = currentAssignment.studentName;
    final targetSession = newSession.trim();

    if (admissionNo.isEmpty || targetSession.isEmpty) return;

    // Next session marked as Left — no class, no subjects
    await promoteStudent(
      currentAssignment: currentAssignment,
      newClassName: 'Left',
      newSession: targetSession,
    );

    await StudentPromotionStorage.addPromotion(
      StudentPromotion(
        admissionNo: admissionNo,
        studentName: studentName,
        fromClass: currentAssignment.className,
        toClass: 'Left',
        fromSession: currentAssignment.session,
        toSession: targetSession,
        average: average,
        eligible: false,
        outcome: 'left',
      ),
    );
  }

  static Future<void> repeatStudent({
    required StudentClass currentAssignment,
    required String newSession,
    double average = 0,
  }) async {
    final admissionNo = currentAssignment.admissionNo.trim();
    final studentName = currentAssignment.studentName;
    final sameClass = currentAssignment.className.trim();
    final targetSession = newSession.trim();

    if (admissionNo.isEmpty || sameClass.isEmpty || targetSession.isEmpty) {
      return;
    }

    // Create / refresh assignment in next session with SAME class
    await promoteStudent(
      currentAssignment: currentAssignment,
      newClassName: sameClass,
      newSession: targetSession,
    );

    await StudentPromotionStorage.addPromotion(
      StudentPromotion(
        admissionNo: admissionNo,
        studentName: studentName,
        fromClass: sameClass,
        toClass: sameClass,
        fromSession: currentAssignment.session,
        toSession: targetSession,
        average: average,
        eligible: false,
        outcome: 'repeated',
      ),
    );
  }

  /// Record a successful promotion in history.
  static Future<void> recordPromotion({
    required StudentClass currentAssignment,
    required String newClassName,
    required String newSession,
    double average = 0,
    String? outcome,
  }) async {
    final resolved = outcome ??
        (newClassName.trim().toLowerCase() == 'graduated'
            ? 'graduated'
            : 'promoted');
    await StudentPromotionStorage.addPromotion(
      StudentPromotion(
        admissionNo: currentAssignment.admissionNo.trim(),
        studentName: currentAssignment.studentName,
        fromClass: currentAssignment.className,
        toClass: newClassName,
        fromSession: currentAssignment.session,
        toSession: newSession,
        average: average,
        eligible: true,
        outcome: resolved,
      ),
    );
  }

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

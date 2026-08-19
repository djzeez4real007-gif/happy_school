import '../models/student.dart';
import '../models/result.dart';
import '../models/report_card.dart';

import '../services/report_card_storage.dart';

class ReportCardGenerator {
  static Future<ReportCard> generate({
    required Student student,
    required List<Result> results,
    required String session,
    required String term,
    required String className,
    required int position,
    required int attendancePresent,
    required int attendanceTotal,
    required String classTeacherRemark,
    required String principalRemark,
    bool? promoted,
    String? promotionStatus,
  }) async {
    final List<ReportCardSubject> subjects = [];

    double totalScore = 0.0;

    for (final result in results) {
      subjects.add(
        ReportCardSubject(
          subjectName: result.subjectName,
          ca1: result.ca1,
          ca2: result.ca2,
          exam: result.exam,
          total: result.total,
          grade: result.grade,
          remark: result.remark,
        ),
      );

      totalScore += result.total;
    }

    final double average = results.isEmpty ? 0.0 : totalScore / results.length;

    String overallGrade = "F9";
    String overallRemark = "Fail";

    if (average >= 75) {
      overallGrade = "A1";
      overallRemark = "Excellent";
    } else if (average >= 70) {
      overallGrade = "B2";
      overallRemark = "Very Good";
    } else if (average >= 65) {
      overallGrade = "B3";
      overallRemark = "Very Good";
    } else if (average >= 60) {
      overallGrade = "C4";
      overallRemark = "Credit";
    } else if (average >= 55) {
      overallGrade = "C5";
      overallRemark = "Credit";
    } else if (average >= 50) {
      overallGrade = "C6";
      overallRemark = "Credit";
    } else if (average >= 45) {
      overallGrade = "D7";
      overallRemark = "Pass";
    } else if (average >= 40) {
      overallGrade = "E8";
      overallRemark = "Pass";
    }

    final reportCard = ReportCard(
      admissionNo: student.admissionNo,
      studentName: student.fullName,
      className: className,
      session: session,
      term: term,
      subjects: subjects,
      total: totalScore,
      average: average,
      overallGrade: overallGrade,
      overallRemark: overallRemark,
      position: position,
      classTeacherRemark: classTeacherRemark,
      principalRemark: principalRemark,
      attendancePresent: attendancePresent,
      attendanceTotal: attendanceTotal,
      promoted: promoted,
      promotionStatus: promotionStatus,
      passportPath: student.passport.isNotEmpty ? student.passport : null,
    );

    await ReportCardStorage.addReportCard(reportCard);

    return reportCard;
  }

  static Future<void> deleteReportCard(int index) async {
    await ReportCardStorage.deleteReportCard(index);
  }

  static Future<List<ReportCard>> getAllReportCards() async {
    return ReportCardStorage.getReportCards();
  }
}

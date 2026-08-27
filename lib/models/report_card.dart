class ReportCard {
  final String admissionNo;
  final String studentName;

  final String className;
  final String session;
  final String term;

  final List<ReportCardSubject> subjects;

  final double total;
  final double average;

  final String overallGrade;
  final String overallRemark;

  final int position;

  final String classTeacherRemark;
  final String principalRemark;

  final int attendancePresent;
  final int attendanceTotal;

  /// null = N/A for non-third term
  final bool? promoted;

  /// promoted | repeated | graduated | not_promoted | null
  final String? promotionStatus;

  /// Local file path to student passport (optional).
  final String? passportPath;

  ReportCard({
    required this.admissionNo,
    required this.studentName,
    required this.className,
    required this.session,
    required this.term,
    required this.subjects,
    required this.total,
    required this.average,
    required this.overallGrade,
    required this.overallRemark,
    required this.position,
    required this.classTeacherRemark,
    required this.principalRemark,
    required this.attendancePresent,
    required this.attendanceTotal,
    this.promoted,
    this.promotionStatus,
    this.passportPath,
  });

  /// Clear label for UI / PDF (ASCII-safe for PDF fonts)
  String get promotionLabel {
    final t = term.trim().toLowerCase();
    final isThird = t == 'third term' || t.contains('third');
    if (!isThird) {
      return 'N/A';
    }
    switch (promotionStatus) {
      case 'promoted':
        return 'Promoted';
      case 'repeated':
        return 'Repeated';
      case 'graduated':
        return 'Graduated';
      case 'left':
        return 'Left school';
      case 'withdrawn':
        return 'Withdrawn';
      case 'not_promoted':
        return 'Not promoted';
      default:
        if (promoted == true) return 'Promoted';
        if (promoted == false) return 'Not promoted';
        return 'Pending decision';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "admissionNo": admissionNo,
      "studentName": studentName,
      "className": className,
      "session": session,
      "term": term,
      "subjects": subjects.map((e) => e.toMap()).toList(),
      "total": total,
      "average": average,
      "overallGrade": overallGrade,
      "overallRemark": overallRemark,
      "position": position,
      "classTeacherRemark": classTeacherRemark,
      "principalRemark": principalRemark,
      "attendancePresent": attendancePresent,
      "attendanceTotal": attendanceTotal,
      "promoted": promoted,
      "promotionStatus": promotionStatus,
      "passportPath": passportPath,
    };
  }

  factory ReportCard.fromMap(Map<String, dynamic> map) {
    final status = map["promotionStatus"]?.toString();
    bool? promoted;
    if (map["promoted"] == null) {
      promoted = null;
    } else {
      promoted = map["promoted"] == true || map["promoted"] == "true";
    }
    // Infer status from old bool if needed
    String? resolved = (status != null && status.isNotEmpty) ? status : null;
    if (resolved == null && promoted == true) resolved = 'promoted';
    if (resolved == null && promoted == false) resolved = 'not_promoted';

    return ReportCard(
      admissionNo: map["admissionNo"] ?? "",
      studentName: map["studentName"] ?? "",
      className: map["className"] ?? "",
      session: map["session"] ?? "",
      term: map["term"] ?? "",
      subjects: (map["subjects"] as List? ?? [])
          .map((e) => ReportCardSubject.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      total: (map["total"] ?? 0).toDouble(),
      average: (map["average"] ?? 0).toDouble(),
      overallGrade: map["overallGrade"] ?? "",
      overallRemark: map["overallRemark"] ?? "",
      position: map["position"] ?? 0,
      classTeacherRemark: map["classTeacherRemark"] ?? "",
      principalRemark: map["principalRemark"] ?? "",
      attendancePresent: map["attendancePresent"] ?? 0,
      attendanceTotal: map["attendanceTotal"] ?? 0,
      promoted: promoted,
      promotionStatus: resolved,
      passportPath: map["passportPath"]?.toString(),
    );
  }
}

class ReportCardSubject {
  final String subjectName;

  final double ca1;
  final double ca2;
  final double exam;

  final double total;

  final String grade;
  final String remark;

  ReportCardSubject({
    required this.subjectName,
    required this.ca1,
    required this.ca2,
    required this.exam,
    required this.total,
    required this.grade,
    required this.remark,
  });

  Map<String, dynamic> toMap() {
    return {
      "subjectName": subjectName,
      "ca1": ca1,
      "ca2": ca2,
      "exam": exam,
      "total": total,
      "grade": grade,
      "remark": remark,
    };
  }

  factory ReportCardSubject.fromMap(Map<String, dynamic> map) {
    return ReportCardSubject(
      subjectName: map["subjectName"] ?? "",
      ca1: (map["ca1"] ?? 0).toDouble(),
      ca2: (map["ca2"] ?? 0).toDouble(),
      exam: (map["exam"] ?? 0).toDouble(),
      total: (map["total"] ?? 0).toDouble(),
      grade: map["grade"] ?? "",
      remark: map["remark"] ?? "",
    );
  }
}

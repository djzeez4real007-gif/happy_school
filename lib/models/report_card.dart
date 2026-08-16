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

  final bool? promoted; // null = N/A (1st/2nd term)

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
  });

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
    };
  }

  factory ReportCard.fromMap(Map<String, dynamic> map) {
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
      promoted: map["promoted"] == null ? null : (map["promoted"] == true || map["promoted"] == "true"),
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

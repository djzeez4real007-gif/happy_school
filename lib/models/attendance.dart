// lib/models/attendance.dart

class Attendance {
  final String id;
  final String admissionNo;
  final String studentName;
  final String className;
  final String session;
  final String term;
  final String date;
  final String status;
  final String remark;

  Attendance({
    required this.id,
    required this.admissionNo,
    required this.studentName,
    required this.className,
    required this.session,
    required this.term,
    required this.date,
    required this.status,
    this.remark = "",
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "admissionNo": admissionNo,
      "studentName": studentName,
      "className": className,
      "session": session,
      "term": term,
      "date": date,
      "status": status,
      "remark": remark,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json["id"]?.toString() ?? "",
      admissionNo: json["admissionNo"]?.toString() ?? "",
      studentName: json["studentName"]?.toString() ?? "",
      className: json["className"]?.toString() ?? "",
      session: json["session"]?.toString() ?? "",
      term: json["term"]?.toString() ?? "",
      date: json["date"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "Present",
      remark: json["remark"]?.toString() ?? "",
    );
  }
}

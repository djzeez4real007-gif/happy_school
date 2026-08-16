class ClassSubject {
  final String className;
  final String subjectCode;
  final String subjectName;
  final String teacherId; // staff id of subject teacher (optional)

  ClassSubject({
    required this.className,
    required this.subjectCode,
    required this.subjectName,
    this.teacherId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'teacherId': teacherId,
    };
  }

  factory ClassSubject.fromMap(Map<String, dynamic> map) {
    return ClassSubject(
      className: map['className'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      teacherId: map['teacherId']?.toString() ?? '',
    );
  }
}

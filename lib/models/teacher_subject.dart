/// Subjects a teacher is allowed to teach (independent of class subject list).
class TeacherSubject {
  final String teacherId;
  final String subjectCode;
  final String subjectName;

  TeacherSubject({
    required this.teacherId,
    required this.subjectCode,
    required this.subjectName,
  });

  Map<String, dynamic> toMap() => {
        'teacherId': teacherId,
        'subjectCode': subjectCode,
        'subjectName': subjectName,
      };

  factory TeacherSubject.fromMap(Map map) => TeacherSubject(
        teacherId: map['teacherId']?.toString() ?? '',
        subjectCode: map['subjectCode']?.toString() ?? '',
        subjectName: map['subjectName']?.toString() ?? '',
      );
}

class StudentSubject {
  final String admissionNo;
  final String studentName;
  final String className;
  final String subjectCode;
  final String subjectName;
  final String session;
  final String term;

  StudentSubject({
    required this.admissionNo,
    required this.studentName,
    required this.className,
    required this.subjectCode,
    required this.subjectName,
    required this.session,
    required this.term,
  });

  Map<String, dynamic> toMap() {
    return {
      'admissionNo': admissionNo,
      'studentName': studentName,
      'className': className,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'session': session,
      'term': term,
    };
  }

  factory StudentSubject.fromMap(Map<String, dynamic> map) {
    return StudentSubject(
      admissionNo: map['admissionNo'] ?? '',
      studentName: map['studentName'] ?? '',
      className: map['className'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      session: map['session'] ?? '',
      term: map['term'] ?? '',
    );
  }
}

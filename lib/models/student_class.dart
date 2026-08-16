class StudentClass {
  final String admissionNo;
  final String studentName;
  final String className;
  final String session;

  // Kept for backward compatibility with existing Hive data.
  // Student class assignment is NO LONGER term-based.
  final String term;

  StudentClass({
    required this.admissionNo,
    required this.studentName,
    required this.className,
    required this.session,
    this.term = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'admissionNo': admissionNo,
      'studentName': studentName,
      'className': className,
      'session': session,
      'term': term,
    };
  }

  factory StudentClass.fromMap(Map<String, dynamic> map) {
    return StudentClass(
      admissionNo: map['admissionNo'] ?? '',
      studentName: map['studentName'] ?? '',
      className: map['className'] ?? '',
      session: map['session'] ?? '',
      term: map['term'] ?? '',
    );
  }
}

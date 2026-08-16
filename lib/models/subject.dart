class Subject {
  final String subjectName;
  final String subjectCode;
  final String studentClass;

  Subject({
    required this.subjectName,
    required this.subjectCode,
    required this.studentClass,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'studentClass': studentClass,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      subjectName: map['subjectName'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      studentClass: map['studentClass'] ?? '',
    );
  }
}

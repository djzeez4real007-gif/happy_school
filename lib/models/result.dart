class Result {
  final String admissionNo;
  final String studentName;
  final String className;
  final String subjectCode;
  final String subjectName;
  final String session;
  final String term;

  final double ca1;
  final double ca2;
  final double exam;

  Result({
    required this.admissionNo,
    required this.studentName,
    required this.className,
    required this.subjectCode,
    required this.subjectName,
    required this.session,
    required this.term,
    required this.ca1,
    required this.ca2,
    required this.exam,
  });

  double get total => ca1 + ca2 + exam;

  double get percentage => total;

  bool get isPassed => total >= 40;

  String get grade {
    if (total >= 75) return "A1";
    if (total >= 70) return "B2";
    if (total >= 65) return "B3";
    if (total >= 60) return "C4";
    if (total >= 55) return "C5";
    if (total >= 50) return "C6";
    if (total >= 45) return "D7";
    if (total >= 40) return "E8";
    return "F9";
  }

  String get remark {
    if (total >= 75) return "Excellent";
    if (total >= 60) return "Very Good";
    if (total >= 50) return "Credit";
    if (total >= 40) return "Pass";
    return "Fail";
  }

  Map<String, dynamic> toMap() {
    return {
      'admissionNo': admissionNo,
      'studentName': studentName,
      'className': className,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'session': session,
      'term': term,
      'ca1': ca1,
      'ca2': ca2,
      'exam': exam,
    };
  }

  factory Result.fromMap(Map<String, dynamic> map) {
    return Result(
      admissionNo: map['admissionNo'] ?? '',
      studentName: map['studentName'] ?? '',
      className: map['className'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      session: map['session'] ?? '',
      term: map['term'] ?? '',
      ca1: _toDouble(map['ca1']),
      ca2: _toDouble(map['ca2']),
      exam: _toDouble(map['exam']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}

class StudentPromotion {
  final String admissionNo;
  final String studentName;

  final String fromClass;
  final String toClass;

  final String fromSession;
  final String toSession;

  final double average;

  final bool eligible;
  final bool selected;

  const StudentPromotion({
    required this.admissionNo,
    required this.studentName,
    required this.fromClass,
    required this.toClass,
    required this.fromSession,
    required this.toSession,
    required this.average,
    required this.eligible,
    this.selected = false,
  });

  StudentPromotion copyWith({
    String? toClass,
    String? toSession,
    bool? selected,
  }) {
    return StudentPromotion(
      admissionNo: admissionNo,
      studentName: studentName,
      fromClass: fromClass,
      toClass: toClass ?? this.toClass,
      fromSession: fromSession,
      toSession: toSession ?? this.toSession,
      average: average,
      eligible: eligible,
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admissionNo': admissionNo,
      'studentName': studentName,
      'fromClass': fromClass,
      'toClass': toClass,
      'fromSession': fromSession,
      'toSession': toSession,
      'average': average,
      'eligible': eligible,
      'selected': selected,
    };
  }

  factory StudentPromotion.fromMap(Map<String, dynamic> map) {
    return StudentPromotion(
      admissionNo: map['admissionNo']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      fromClass: map['fromClass']?.toString() ?? '',
      toClass: map['toClass']?.toString() ?? '',
      fromSession: map['fromSession']?.toString() ?? '',
      toSession: map['toSession']?.toString() ?? '',
      average: (map['average'] as num?)?.toDouble() ?? 0.0,
      eligible: map['eligible'] == true,
      selected: map['selected'] == true,
    );
  }
}

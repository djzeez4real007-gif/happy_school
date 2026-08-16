class SchoolClass {
  final String className;
  final String arm;

  final String teacherId;
  final String classTeacher;

  final int capacity;

  SchoolClass({
    required this.className,
    required this.arm,
    required this.teacherId,
    required this.classTeacher,
    required this.capacity,
  });

  String get fullClassName => "$className $arm";

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'arm': arm,
      'teacherId': teacherId,
      'classTeacher': classTeacher,
      'capacity': capacity,
    };
  }

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      className: map['className'] ?? '',
      arm: map['arm'] ?? '',
      teacherId: map['teacherId'] ?? '',
      classTeacher: map['classTeacher'] ?? '',
      capacity: map['capacity'] ?? 0,
    );
  }
}

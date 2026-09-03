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

  String get fullClassName => "$className $arm".trim();

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchoolClass &&
        fullClassName.toLowerCase() == other.fullClassName.toLowerCase();
  }

  @override
  int get hashCode => fullClassName.toLowerCase().hashCode;
}

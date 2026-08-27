class Teacher {
  final String staffId;
  final String surname;
  final String firstName;
  final String middleName;
  final String gender;
  final String phone;
  final String email;
  final String address;
  final String qualification;
  final String department;
  final String passport;
  /// Full-time | Part-time
  final String employmentType;

  Teacher({
    required this.staffId,
    required this.surname,
    required this.firstName,
    required this.middleName,
    required this.gender,
    required this.phone,
    required this.email,
    required this.address,
    required this.qualification,
    required this.department,
    required this.passport,
    this.employmentType = 'Full-time',
  });

  String get fullName => "$surname $firstName $middleName".trim();

  bool get isPartTime {
    final t = employmentType.trim().toLowerCase().replaceAll(' ', '');
    return t == 'part-time' || t == 'parttime' || t.contains('part');
  }

  bool get isFullTime => !isPartTime;

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'surname': surname,
      'firstName': firstName,
      'middleName': middleName,
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
      'qualification': qualification,
      'department': department,
      'passport': passport,
      'employmentType': employmentType,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      staffId: map['staffId']?.toString() ?? '',
      surname: map['surname']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      middleName: map['middleName']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      qualification: map['qualification']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      passport: map['passport']?.toString() ?? '',
      employmentType: (map['employmentType']?.toString().trim().isNotEmpty == true)
          ? map['employmentType'].toString()
          : 'Full-time',
    );
  }
}

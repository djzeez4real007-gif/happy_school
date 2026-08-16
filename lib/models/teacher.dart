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
  });

  String get fullName => "$surname $firstName $middleName";

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
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      staffId: map['staffId'] ?? '',
      surname: map['surname'] ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      gender: map['gender'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      qualification: map['qualification'] ?? '',
      department: map['department'] ?? '',
      passport: map['passport'] ?? '',
    );
  }
}

class Student {
  final String admissionNo;
  final String surname;
  final String firstName;
  final String middleName;
  final String gender;
  final String dateOfBirth;
  final String parentName;
  final String phone;
  final String email;
  final String address;
  final String state;
  final String localGovernment;
  final String nationality;
  final String religion;
  final String bloodGroup;
  final String genotype;
  final String medicalCondition;
  final String passport;

  Student({
    required this.admissionNo,
    required this.surname,
    required this.firstName,
    required this.middleName,
    required this.gender,
    required this.dateOfBirth,
    required this.parentName,
    required this.phone,
    required this.email,
    required this.address,
    required this.state,
    required this.localGovernment,
    required this.nationality,
    required this.religion,
    required this.bloodGroup,
    required this.genotype,
    required this.medicalCondition,
    required this.passport,
  });

  String get fullName => "$surname $firstName $middleName";

  // Convert Student object to Hive format
  Map<String, dynamic> toMap() {
    return {
      'admissionNo': admissionNo,
      'surname': surname,
      'firstName': firstName,
      'middleName': middleName,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'parentName': parentName,
      'phone': phone,
      'email': email,
      'address': address,
      'state': state,
      'localGovernment': localGovernment,
      'nationality': nationality,
      'religion': religion,
      'bloodGroup': bloodGroup,
      'genotype': genotype,
      'medicalCondition': medicalCondition,
      'passport': passport,
    };
  }

  // Convert Hive data back to Student object
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      admissionNo: map['admissionNo'] ?? '',
      surname: map['surname'] ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      gender: map['gender'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      parentName: map['parentName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      state: map['state'] ?? '',
      localGovernment: map['localGovernment'] ?? '',
      nationality: map['nationality'] ?? '',
      religion: map['religion'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      genotype: map['genotype'] ?? '',
      medicalCondition: map['medicalCondition'] ?? '',
      passport: map['passport'] ?? '',
    );
  }
}

class StaffMember {
  final String id;
  final String fullName;
  final String gender;
  final String phone;
  final String email;
  final String address;
  final String post;
  final String staffType; // non_teaching
  final String employmentDate;
  final bool active;
  final String passport; // file path
  final String qualification; // primary: WAEC, NECO, etc.
  final String otherQualifications; // free text e.g. Trade Test, first aid
  final String note;
  final String createdAt;
  final String updatedAt;

  StaffMember({
    required this.id,
    required this.fullName,
    this.gender = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    required this.post,
    this.staffType = 'non_teaching',
    this.employmentDate = '',
    this.active = true,
    this.passport = '',
    this.qualification = '',
    this.otherQualifications = '',
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'gender': gender,
        'phone': phone,
        'email': email,
        'address': address,
        'post': post,
        'staffType': staffType,
        'employmentDate': employmentDate,
        'active': active,
        'passport': passport,
        'photoPath': passport, // alias for older code
        'qualification': qualification,
        'otherQualifications': otherQualifications,
        'note': note,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory StaffMember.fromMap(Map map) => StaffMember(
        id: map['id']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        gender: map['gender']?.toString() ?? '',
        phone: map['phone']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        address: map['address']?.toString() ?? '',
        post: map['post']?.toString() ?? '',
        staffType: map['staffType']?.toString() ?? 'non_teaching',
        employmentDate: map['employmentDate']?.toString() ?? '',
        active: map['active'] != false,
        passport: (map['passport'] ?? map['photoPath'])?.toString() ?? '',
        qualification: map['qualification']?.toString() ?? '',
        otherQualifications: map['otherQualifications']?.toString() ?? '',
        note: map['note']?.toString() ?? '',
        createdAt: map['createdAt']?.toString() ?? '',
        updatedAt: map['updatedAt']?.toString() ?? '',
      );

  StaffMember copyWith({
    String? fullName,
    String? gender,
    String? phone,
    String? email,
    String? address,
    String? post,
    String? employmentDate,
    bool? active,
    String? passport,
    String? qualification,
    String? otherQualifications,
    String? note,
    String? updatedAt,
  }) {
    return StaffMember(
      id: id,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      post: post ?? this.post,
      staffType: staffType,
      employmentDate: employmentDate ?? this.employmentDate,
      active: active ?? this.active,
      passport: passport ?? this.passport,
      qualification: qualification ?? this.qualification,
      otherQualifications: otherQualifications ?? this.otherQualifications,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

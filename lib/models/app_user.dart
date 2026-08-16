class AppUser {
  final String id;
  final String fullName;
  final String username;
  final String passwordHash;
  final String role; // admin, principal, class_teacher, subject_teacher, accountant, parent
  final bool isActive;
  final String? linkedTeacherId;
  /// Comma-separated admission numbers for parent (supports 2–3 children)
  final String? linkedAdmissionNos;

  AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
    this.linkedTeacherId,
    this.linkedAdmissionNos,
  });

  /// Parsed list of child admission numbers
  List<String> get childrenAdmissionNos {
    if (linkedAdmissionNos == null || linkedAdmissionNos!.trim().isEmpty) {
      return [];
    }
    return linkedAdmissionNos!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'passwordHash': passwordHash,
      'role': role,
      'isActive': isActive,
      'linkedTeacherId': linkedTeacherId ?? '',
      'linkedAdmissionNos': linkedAdmissionNos ?? '',
      // backward compat
      'linkedAdmissionNo': childrenAdmissionNos.isNotEmpty
          ? childrenAdmissionNos.first
          : '',
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    // Prefer linkedAdmissionNos; fall back to single linkedAdmissionNo
    String? nos = map['linkedAdmissionNos']?.toString();
    if (nos == null || nos.isEmpty) {
      final single = map['linkedAdmissionNo']?.toString() ?? '';
      nos = single.isEmpty ? null : single;
    }
    return AppUser(
      id: map['id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      passwordHash: map['passwordHash']?.toString() ?? '',
      role: map['role']?.toString() ?? 'subject_teacher',
      isActive: map['isActive'] == true || map['isActive'] == 'true',
      linkedTeacherId: (map['linkedTeacherId']?.toString().isEmpty ?? true)
          ? null
          : map['linkedTeacherId'].toString(),
      linkedAdmissionNos: nos,
    );
  }

  AppUser copyWith({
    String? fullName,
    String? username,
    String? passwordHash,
    String? role,
    bool? isActive,
    String? linkedTeacherId,
    String? linkedAdmissionNos,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      linkedTeacherId: linkedTeacherId ?? this.linkedTeacherId,
      linkedAdmissionNos: linkedAdmissionNos ?? this.linkedAdmissionNos,
    );
  }

  static const List<String> allRoles = [
    'admin',
    'principal',
    'class_teacher',
    'subject_teacher',
    'accountant',
    'parent',
  ];

  static String roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'principal':
        return 'Principal';
      case 'class_teacher':
        return 'Class Teacher';
      case 'subject_teacher':
        return 'Subject Teacher';
      case 'accountant':
        return 'Accountant';
      case 'parent':
        return 'Parent';
      default:
        return role;
    }
  }
}

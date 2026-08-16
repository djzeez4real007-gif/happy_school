class AuditLog {
  final String id;
  final String action; // result_saved, fee_saved, promotion, user_deleted, etc.
  final String module; // results, fees, promotion, users
  final String description;
  final String userId;
  final String userName;
  final String userRole;
  final String timestamp; // ISO or display string
  final String? refId; // admission no, receipt no, etc.

  AuditLog({
    required this.id,
    required this.action,
    required this.module,
    required this.description,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.timestamp,
    this.refId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'action': action,
        'module': module,
        'description': description,
        'userId': userId,
        'userName': userName,
        'userRole': userRole,
        'timestamp': timestamp,
        'refId': refId ?? '',
      };

  factory AuditLog.fromMap(Map<String, dynamic> map) => AuditLog(
        id: map['id']?.toString() ?? '',
        action: map['action']?.toString() ?? '',
        module: map['module']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        userName: map['userName']?.toString() ?? '',
        userRole: map['userRole']?.toString() ?? '',
        timestamp: map['timestamp']?.toString() ?? '',
        refId: (map['refId']?.toString().isEmpty ?? true)
            ? null
            : map['refId'].toString(),
      );
}

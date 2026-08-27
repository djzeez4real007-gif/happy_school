class AuditLog {
  final String id;
  final String action;
  final String module;
  final String description;
  final String userId;
  final String userName;
  final String userRole;
  final String timestamp;
  final String? refId;
  final String? session;
  final String? term;

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
    this.session,
    this.term,
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
        'session': session ?? '',
        'term': term ?? '',
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
        session: (map['session']?.toString().isEmpty ?? true)
            ? null
            : map['session'].toString(),
        term: (map['term']?.toString().isEmpty ?? true)
            ? null
            : map['term'].toString(),
      );
}

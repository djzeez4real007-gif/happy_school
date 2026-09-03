/// Commercial licence / subscription for this school installation.
enum LicencePlan {
  trial,
  oneTime,
  monthly,
  yearly,
  perStudent,
}

extension LicencePlanX on LicencePlan {
  String get label {
    switch (this) {
      case LicencePlan.trial:
        return 'Trial';
      case LicencePlan.oneTime:
        return 'One-time licence';
      case LicencePlan.monthly:
        return 'Monthly subscription';
      case LicencePlan.yearly:
        return 'Yearly subscription';
      case LicencePlan.perStudent:
        return 'Per-student billing';
    }
  }

  static LicencePlan fromString(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'onetime':
      case 'one_time':
      case 'one-time':
        return LicencePlan.oneTime;
      case 'monthly':
        return LicencePlan.monthly;
      case 'yearly':
      case 'annual':
        return LicencePlan.yearly;
      case 'perstudent':
      case 'per_student':
      case 'per-student':
        return LicencePlan.perStudent;
      default:
        return LicencePlan.trial;
    }
  }

  String get storageValue {
    switch (this) {
      case LicencePlan.trial:
        return 'trial';
      case LicencePlan.oneTime:
        return 'one_time';
      case LicencePlan.monthly:
        return 'monthly';
      case LicencePlan.yearly:
        return 'yearly';
      case LicencePlan.perStudent:
        return 'per_student';
    }
  }
}

class SchoolLicence {
  final LicencePlan plan;
  final DateTime? expiresAt;
  final int maxStudents;
  final bool active;
  final String notes;
  final String contactPhone;
  final String contactWhatsapp;
  final double? priceAmount;
  final String currency;
  final DateTime? activatedAt;
  final String licenceKey;

  const SchoolLicence({
    this.plan = LicencePlan.trial,
    this.expiresAt,
    this.maxStudents = 50,
    this.active = true,
    this.notes = '',
    this.contactPhone = '07068791117',
    this.contactWhatsapp = '07068791117',
    this.priceAmount,
    this.currency = 'NGN',
    this.activatedAt,
    this.licenceKey = '',
  });

  static SchoolLicence get defaults {
    final now = DateTime.now();
    return SchoolLicence(
      plan: LicencePlan.trial,
      expiresAt: now.add(const Duration(days: 7)),
      maxStudents: 50,
      active: true,
      notes: 'Default 7-day trial',
      activatedAt: now,
    );
  }

  bool get isExpired {
    if (!active) return true;
    if (plan == LicencePlan.oneTime) return false;
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  bool get isExpiringSoon {
    if (isExpired || plan == LicencePlan.oneTime) return false;
    final exp = expiresAt;
    if (exp == null) return false;
    return exp.difference(DateTime.now()).inDays <= 14;
  }

  int? get daysRemaining {
    if (plan == LicencePlan.oneTime) return null;
    final exp = expiresAt;
    if (exp == null) return null;
    return exp.difference(DateTime.now()).inDays;
  }

  String get statusLabel {
    if (!active) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isExpiringSoon) return 'Expiring soon';
    return 'Active';
  }

  SchoolLicence copyWith({
    LicencePlan? plan,
    DateTime? expiresAt,
    int? maxStudents,
    bool? active,
    String? notes,
    String? contactPhone,
    String? contactWhatsapp,
    double? priceAmount,
    String? currency,
    DateTime? activatedAt,
    String? licenceKey,
    bool clearExpiry = false,
  }) {
    return SchoolLicence(
      plan: plan ?? this.plan,
      expiresAt: clearExpiry ? null : (expiresAt ?? this.expiresAt),
      maxStudents: maxStudents ?? this.maxStudents,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      contactPhone: contactPhone ?? this.contactPhone,
      contactWhatsapp: contactWhatsapp ?? this.contactWhatsapp,
      priceAmount: priceAmount ?? this.priceAmount,
      currency: currency ?? this.currency,
      activatedAt: activatedAt ?? this.activatedAt,
      licenceKey: licenceKey ?? this.licenceKey,
    );
  }

  Map<String, dynamic> toMap() => {
        'plan': plan.storageValue,
        'expiresAt': expiresAt?.toIso8601String(),
        'maxStudents': maxStudents,
        'active': active,
        'notes': notes,
        'contactPhone': contactPhone,
        'contactWhatsapp': contactWhatsapp,
        'priceAmount': priceAmount,
        'currency': currency,
        'activatedAt': activatedAt?.toIso8601String(),
        'licenceKey': licenceKey,
      };

  factory SchoolLicence.fromMap(Map map) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return SchoolLicence(
      plan: LicencePlanX.fromString(map['plan']?.toString()),
      expiresAt: parse(map['expiresAt']),
      maxStudents: int.tryParse('${map['maxStudents']}') ?? 50,
      active: map['active'] != false,
      notes: (map['notes'] ?? '').toString(),
      contactPhone: (map['contactPhone'] ?? '07068791117').toString(),
      contactWhatsapp: (map['contactWhatsapp'] ?? '07068791117').toString(),
      priceAmount: map['priceAmount'] == null
          ? null
          : double.tryParse('${map['priceAmount']}'),
      currency: (map['currency'] ?? 'NGN').toString(),
      activatedAt: parse(map['activatedAt']),
      licenceKey: (map['licenceKey'] ?? '').toString(),
    );
  }
}

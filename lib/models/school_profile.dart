import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class SchoolProfile {
  final String name;
  final String motto;
  final String address;
  final String phone;
  final String email;
  final String logoPath;
  final String logoBase64;
  final int primaryColorValue;
  final int accentColorValue;

  const SchoolProfile({
    this.name = 'Happy School',
    this.motto = 'Knowledge is light',
    this.address = 'Bolakale Street, Checking Point, Ilorin, Nigeria',
    this.phone = '07068791117',
    this.email = 'thehappyone2019@gmail.com',
    this.logoPath = '',
    this.logoBase64 = '',
    this.primaryColorValue = 0xFF1D4ED8,
    this.accentColorValue = 0xFF3B82F6,
  });

  static const SchoolProfile defaults = SchoolProfile();

  Color get primaryColor => Color(primaryColorValue);
  Color get accentColor => Color(accentColorValue);

  bool get hasCustomLogo =>
      logoBase64.trim().isNotEmpty || logoPath.trim().isNotEmpty;

  Uint8List? get logoBytes {
    final b64 = logoBase64.trim();
    if (b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  SchoolProfile copyWith({
    String? name,
    String? motto,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
    String? logoBase64,
    int? primaryColorValue,
    int? accentColorValue,
  }) {
    return SchoolProfile(
      name: name ?? this.name,
      motto: motto ?? this.motto,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoPath: logoPath ?? this.logoPath,
      logoBase64: logoBase64 ?? this.logoBase64,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      accentColorValue: accentColorValue ?? this.accentColorValue,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'motto': motto,
        'address': address,
        'phone': phone,
        'email': email,
        'logoPath': logoPath,
        'logoBase64': logoBase64,
        'primaryColorValue': primaryColorValue,
        'accentColorValue': accentColorValue,
      };

  factory SchoolProfile.fromMap(Map map) {
    return SchoolProfile(
      name: (map['name'] ?? 'Happy School').toString(),
      motto: (map['motto'] ?? 'Knowledge is light').toString(),
      address: (map['address'] ??
              'Bolakale Street, Checking Point, Ilorin, Nigeria')
          .toString(),
      phone: (map['phone'] ?? '07068791117').toString(),
      email: (map['email'] ?? 'thehappyone2019@gmail.com').toString(),
      logoPath: (map['logoPath'] ?? '').toString(),
      logoBase64: (map['logoBase64'] ?? '').toString(),
      primaryColorValue: (map['primaryColorValue'] is int)
          ? map['primaryColorValue'] as int
          : int.tryParse('${map['primaryColorValue']}') ?? 0xFF1D4ED8,
      accentColorValue: (map['accentColorValue'] is int)
          ? map['accentColorValue'] as int
          : int.tryParse('${map['accentColorValue']}') ?? 0xFF3B82F6,
    );
  }
}

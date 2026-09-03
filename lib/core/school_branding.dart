import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'school_profile_controller.dart';

/// Shared school logo / identity helpers for UI + PDFs.
class SchoolBranding {
  SchoolBranding._();

  static ImageProvider logoProvider() {
    final bytes = SchoolProfileController.instance.profile.logoBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }
    return const AssetImage('assets/images/school_logo.png');
  }

  /// Circle or rounded logo suitable for headers.
  static Widget logo({
    double size = 72,
    BoxShape shape = BoxShape.circle,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    final bytes = SchoolProfileController.instance.profile.logoBytes;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: borderRadius == null ? shape : BoxShape.rectangle,
        borderRadius: borderRadius,
        border: border,
        color: Colors.white,
        image: DecorationImage(
          image: bytes != null && bytes.isNotEmpty
              ? MemoryImage(bytes)
              : const AssetImage('assets/images/school_logo.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  static String get name => SchoolProfileController.instance.name;
  static String get motto => SchoolProfileController.instance.motto;
  static String get address => SchoolProfileController.instance.address;
  static String get phone => SchoolProfileController.instance.phone;
  static String get email => SchoolProfileController.instance.email;

  /// Logo bytes for PDF (null → caller should load asset).
  static Uint8List? get logoBytes =>
      SchoolProfileController.instance.profile.logoBytes;
}

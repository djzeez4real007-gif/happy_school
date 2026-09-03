import 'package:flutter/material.dart';

import 'licence_controller.dart';
import '../services/auth_service.dart';
import '../services/student_storage.dart';

class LicenceGuard {
  static bool get isVendor =>
      AuthService.currentRole.trim().toLowerCase() == 'vendor';

  static bool get isLocked {
    if (isVendor) return false;
    final l = LicenceController.instance.licence;
    return !l.active || l.isExpired;
  }

  static String get lockMessage {
    final l = LicenceController.instance.licence;
    if (!l.active) {
      return 'This school licence is inactive. Contact the software vendor to reactivate.';
    }
    return 'Your subscription has expired. Contact the vendor to renew.\nWhatsApp: ${l.contactWhatsapp}';
  }

  static Future<String?> checkCanAddStudent() async {
    if (isVendor) return null;
    if (isLocked) return lockMessage;
    try {
      final students = await StudentStorage.getStudents();
      final count = students.length;
      if (!LicenceController.instance.canRegisterMoreStudents(count)) {
        final max = LicenceController.instance.maxStudents;
        return 'Student limit reached ($max). Ask the vendor to upgrade the plan.';
      }
    } catch (_) {}
    return null;
  }

  static String? checkCanWrite() {
    if (isVendor) return null;
    if (isLocked) return lockMessage;
    return null;
  }

  static void showBlocked(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFDC2626),
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static Future<bool> ensureWritable(BuildContext context) async {
    final reason = checkCanWrite();
    if (reason != null) {
      showBlocked(context, reason);
      return false;
    }
    return true;
  }

  static Future<bool> ensureCanAddStudent(BuildContext context) async {
    final reason = await checkCanAddStudent();
    if (reason != null) {
      showBlocked(context, reason);
      return false;
    }
    return true;
  }
}

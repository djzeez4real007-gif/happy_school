import 'package:hive_flutter/hive_flutter.dart';

import '../models/school_fee.dart';

class SchoolFeeStorage {
  static const String boxName = 'school_fees';

  static String _normClass(String name) =>
      name.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static String _normText(String value) => value.trim().toLowerCase();

  static Future<void> saveFee(SchoolFee fee) async {
    final box = Hive.box<Map>(boxName);

    for (int i = 0; i < box.length; i++) {
      final item = SchoolFee.fromMap(Map<String, dynamic>.from(box.getAt(i)!));

      if (_normClass(item.className) == _normClass(fee.className) &&
          _normText(item.session) == _normText(fee.session) &&
          _normText(item.term) == _normText(fee.term)) {
        await box.putAt(i, fee.toMap());
        return;
      }
    }

    await box.add(fee.toMap());
  }

  /// Save the same fee amounts for every term in the session.
  static Future<void> saveFeeForAllTerms(SchoolFee fee) async {
    const terms = ['First Term', 'Second Term', 'Third Term'];
    for (final term in terms) {
      await saveFee(
        SchoolFee(
          className: fee.className,
          tuitionFee: fee.tuitionFee,
          examinationFee: fee.examinationFee,
          ptaFee: fee.ptaFee,
          ictFee: fee.ictFee,
          sportFee: fee.sportFee,
          developmentLevy: fee.developmentLevy,
          otherCharges: fee.otherCharges,
          session: fee.session,
          term: term,
        ),
      );
    }
  }

  static Future<List<SchoolFee>> getFees() async {
    final box = Hive.box<Map>(boxName);
    final list = box.values
        .map((e) => SchoolFee.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    list.sort((a, b) {
      final c = a.className.compareTo(b.className);
      if (c != 0) return c;
      final s = a.session.compareTo(b.session);
      if (s != 0) return s;
      return a.term.compareTo(b.term);
    });
    return list;
  }

  /// Lookup fee by class + session + term.
  /// Class names are normalized ("JSS1 A" == "JSS1A").
  /// Session/term are trimmed case-insensitive.
  static Future<SchoolFee?> getFee(
    String className,
    String session,
    String term,
  ) async {
    final fees = await getFees();
    final norm = _normClass(className);
    final sess = _normText(session);
    final trm = _normText(term);

    // 1) Exact normalized match
    for (final fee in fees) {
      if (_normClass(fee.className) == norm &&
          _normText(fee.session) == sess &&
          _normText(fee.term) == trm) {
        return fee;
      }
    }

    // 2) Soft class match: "JSS1" fee applies to "JSS1 A" (and reverse)
    //    Still requires same session + term (no cross-term bleed).
    for (final fee in fees) {
      if (_normText(fee.session) != sess || _normText(fee.term) != trm) {
        continue;
      }
      final feeNorm = _normClass(fee.className);
      if (feeNorm.isEmpty || norm.isEmpty) continue;
      if (feeNorm == norm) return fee;
      if (norm.startsWith(feeNorm) || feeNorm.startsWith(norm)) {
        return fee;
      }
    }

    return null;
  }

  static Future<void> deleteFee(int index) async {
    final box = Hive.box<Map>(boxName);
    await box.deleteAt(index);
  }

  static Future<void> updateFee(int index, SchoolFee fee) async {
    final box = Hive.box<Map>(boxName);
    await box.putAt(index, fee.toMap());
  }
}

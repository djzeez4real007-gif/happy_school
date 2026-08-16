import 'package:hive_flutter/hive_flutter.dart';

import '../models/school_fee.dart';

class SchoolFeeStorage {
  static const String boxName = 'school_fees';

  static Future<void> saveFee(SchoolFee fee) async {
    final box = Hive.box<Map>(boxName);

    for (int i = 0; i < box.length; i++) {
      final item = SchoolFee.fromMap(Map<String, dynamic>.from(box.getAt(i)!));

      if (item.className == fee.className &&
          item.session == fee.session &&
          item.term == fee.term) {
        await box.putAt(i, fee.toMap());
        return;
      }
    }

    await box.add(fee.toMap());
  }

  static Future<List<SchoolFee>> getFees() async {
    final box = Hive.box<Map>(boxName);
    return box.values
        .map((e) => SchoolFee.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<SchoolFee?> getFee(
    String className,
    String session,
    String term,
  ) async {
    final fees = await getFees();

    // Exact match
    for (final fee in fees) {
      if (fee.className == className &&
          fee.session == session &&
          fee.term == term) {
        return fee;
      }
    }

    // Session + class (any term)
    for (final fee in fees) {
      if (fee.className == className && fee.session == session) {
        return fee;
      }
    }

    // Class only (latest defined fee for that class)
    for (final fee in fees.reversed) {
      if (fee.className == className) {
        return fee;
      }
    }

    // Normalize class names: "JSS1 A" vs "JSS1A"
    final norm = className.replaceAll(' ', '').toLowerCase();
    for (final fee in fees.reversed) {
      if (fee.className.replaceAll(' ', '').toLowerCase() == norm) {
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

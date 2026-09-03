import 'package:hive_flutter/hive_flutter.dart';

import '../models/pricing_package.dart';

class PricingStorage {
  static const boxName = 'pricing_packages';
  static const _key = 'packages';

  static Future<void> open() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Future<List<PricingPackage>> load() async {
    await open();
    final raw = Hive.box(boxName).get(_key);
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((m) => PricingPackage.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    final defaults = PricingPackage.defaults;
    await save(defaults);
    return List.from(defaults);
  }

  static Future<void> save(List<PricingPackage> packages) async {
    await open();
    await Hive.box(boxName).put(
      _key,
      packages.map((p) => p.toMap()).toList(),
    );
  }
}

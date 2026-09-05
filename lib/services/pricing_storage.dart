import '../database/fs.dart';
import '../models/pricing_package.dart';

class PricingStorage {
  static const boxName = 'pricing_packages';
  static const _key = 'packages';

  static Future<List<PricingPackage>> load() async {
    final raw = await Fs.getSingleton(boxName, _key);
    if (raw != null && raw['items'] is List) {
      return (raw['items'] as List)
          .whereType<Map>()
          .map((m) => PricingPackage.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    final defaults = PricingPackage.defaults;
    await save(defaults);
    return List.from(defaults);
  }

  static Future<void> save(List<PricingPackage> packages) async {
    await Fs.setSingleton(boxName, _key, {
      'items': packages.map((p) => p.toMap()).toList(),
    });
  }
}

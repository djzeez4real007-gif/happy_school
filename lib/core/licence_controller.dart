import 'package:flutter/material.dart';

import '../models/pricing_package.dart';
import '../models/school_licence.dart';
import '../services/licence_storage.dart';
import '../services/pricing_storage.dart';

class LicenceController extends ChangeNotifier {
  LicenceController._();
  static final LicenceController instance = LicenceController._();

  SchoolLicence _licence = SchoolLicence.defaults;
  List<PricingPackage> _packages = PricingPackage.defaults;

  SchoolLicence get licence => _licence;
  List<PricingPackage> get packages => List.unmodifiable(_packages);

  bool get isExpired => _licence.isExpired;
  bool get isActive => _licence.active && !_licence.isExpired;
  int get maxStudents => _licence.maxStudents;

  Future<void> load() async {
    _licence = await LicenceStorage.load();
    _packages = await PricingStorage.load();
    notifyListeners();
  }

  Future<void> save(SchoolLicence licence) async {
    _licence = licence;
    await LicenceStorage.save(licence);
    notifyListeners();
  }

  Future<void> savePackages(List<PricingPackage> packages) async {
    _packages = packages;
    await PricingStorage.save(packages);
    notifyListeners();
  }

  bool canRegisterMoreStudents(int currentCount) {
    if (!isActive) return false;
    return currentCount < _licence.maxStudents;
  }
}

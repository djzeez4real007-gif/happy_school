import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../services/school_profile_storage.dart';

class SchoolProfileController extends ChangeNotifier {
  SchoolProfileController._();
  static final SchoolProfileController instance = SchoolProfileController._();

  SchoolProfile _profile = SchoolProfile.defaults;
  SchoolProfile get profile => _profile;

  String get name => _profile.name;
  String get motto => _profile.motto;
  String get address => _profile.address;
  String get phone => _profile.phone;
  String get email => _profile.email;
  Color get primary => _profile.primaryColor;
  Color get accent => _profile.accentColor;

  Future<void> load() async {
    _profile = await SchoolProfileStorage.load();
    notifyListeners();
  }

  Future<void> save(SchoolProfile profile) async {
    _profile = profile;
    await SchoolProfileStorage.save(profile);
    notifyListeners();
  }
}

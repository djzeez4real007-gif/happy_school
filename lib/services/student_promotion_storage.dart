import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_promotion.dart';

class StudentPromotionStorage {
  static const String storageKey = "student_promotions";

  // ==========================================================
  // GET ALL PROMOTION RECORDS
  // ==========================================================

  static Future<List<StudentPromotion>> getPromotions() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString(storageKey);

    if (json == null || json.isEmpty) {
      return [];
    }

    final List<dynamic> data = jsonDecode(json);

    return data
        .map((e) => StudentPromotion.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  static Future<void> savePromotions(List<StudentPromotion> promotions) async {
    final prefs = await SharedPreferences.getInstance();

    final json = jsonEncode(promotions.map((e) => e.toMap()).toList());

    await prefs.setString(storageKey, json);
  }

  // ==========================================================
  // ADD PROMOTION RECORD
  // ==========================================================

  static Future<void> addPromotion(StudentPromotion promotion) async {
    final promotions = await getPromotions();

    promotions.add(promotion);

    await savePromotions(promotions);
  }

  // ==========================================================
  // CLEAR HISTORY
  // ==========================================================

  static Future<void> clearPromotions() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(storageKey);
  }
}

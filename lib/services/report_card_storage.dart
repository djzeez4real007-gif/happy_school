import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_card.dart';

class ReportCardStorage {
  static const String storageKey = "report_cards";

  static Future<List<ReportCard>> getReportCards() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString(storageKey);

    if (json == null) {
      return [];
    }

    final List data = jsonDecode(json);

    return data
        .map((e) => ReportCard.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveReportCards(List<ReportCard> reportCards) async {
    final prefs = await SharedPreferences.getInstance();

    final json = jsonEncode(reportCards.map((e) => e.toMap()).toList());

    await prefs.setString(storageKey, json);
  }

  static Future<void> addReportCard(ReportCard reportCard) async {
    final reportCards = await getReportCards();

    reportCards.add(reportCard);

    await saveReportCards(reportCards);
  }

  static Future<void> updateReportCard(int index, ReportCard reportCard) async {
    final reportCards = await getReportCards();

    if (index < 0 || index >= reportCards.length) return;

    reportCards[index] = reportCard;

    await saveReportCards(reportCards);
  }

  static Future<void> deleteReportCard(int index) async {
    final reportCards = await getReportCards();

    if (index < 0 || index >= reportCards.length) return;

    reportCards.removeAt(index);

    await saveReportCards(reportCards);
  }

  static Future<void> clearReportCards() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(storageKey);
  }
}

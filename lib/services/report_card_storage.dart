import '../database/fs.dart';
import '../models/report_card.dart';

class ReportCardStorage {
  static const String boxName = 'report_cards';

  static Future<List<ReportCard>> getReportCards() async {
    final list = <ReportCard>[];
    for (final e in await Fs.getAll(boxName)) {
      try {
        list.add(ReportCard.fromMap(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> saveReportCards(List<ReportCard> reportCards) async {
    for (final r in await Fs.getAll(boxName)) {
      final id = r['_docId']?.toString();
      if (id != null) await Fs.delete(boxName, id);
    }
    for (final c in reportCards) {
      await Fs.add(boxName, c.toMap());
    }
  }

  static Future<void> addReportCard(ReportCard reportCard) async {
    await Fs.add(boxName, reportCard.toMap());
  }

  static Future<void> updateReportCard(int index, ReportCard reportCard) async {
    await Fs.putAt(boxName, index, reportCard.toMap());
  }

  static Future<void> deleteReportCard(int index) async {
    await Fs.deleteAt(boxName, index);
  }

  static Future<void> clearReportCards() async {
    for (final r in await Fs.getAll(boxName)) {
      final id = r['_docId']?.toString();
      if (id != null) await Fs.delete(boxName, id);
    }
  }
}

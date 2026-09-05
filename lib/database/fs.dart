import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Online Firestore access — path: schools/{schoolId}/{collection}/{doc}
class Fs {
  static String schoolId = 'default';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get schoolDoc =>
      _db.collection('schools').doc(schoolId);

  static CollectionReference<Map<String, dynamic>> col(String name) =>
      schoolDoc.collection(name);

  static Future<List<Map<String, dynamic>>> getAll(String name) async {
    final snap = await col(name).get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['_docId'] = d.id;
      return m;
    }).toList();
  }

  static Future<Map<String, dynamic>?> getDoc(String name, String id) async {
    final d = await col(name).doc(id).get();
    if (!d.exists || d.data() == null) return null;
    final m = Map<String, dynamic>.from(d.data()!);
    m['_docId'] = d.id;
    return m;
  }

  static Future<String> add(String name, Map<String, dynamic> data) async {
    final clean = Map<String, dynamic>.from(data)..remove('_docId');
    clean['updatedAt'] = FieldValue.serverTimestamp();
    if (!clean.containsKey('createdAt')) {
      clean['createdAt'] = FieldValue.serverTimestamp();
    }
    final ref = await col(name).add(clean);
    return ref.id;
  }

  static Future<void> set(
    String name,
    String id,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    final clean = Map<String, dynamic>.from(data)..remove('_docId');
    clean['updatedAt'] = FieldValue.serverTimestamp();
    await col(name).doc(id).set(clean, SetOptions(merge: merge));
  }

  static Future<void> delete(String name, String id) async {
    await col(name).doc(id).delete();
  }

  static Future<void> putAt(String name, int index, Map<String, dynamic> data) async {
    final all = await getAll(name);
    if (index < 0 || index >= all.length) {
      await add(name, data);
      return;
    }
    final id = all[index]['_docId']?.toString();
    if (id == null || id.isEmpty) {
      await add(name, data);
      return;
    }
    await set(name, id, data);
  }

  static Future<void> deleteAt(String name, int index) async {
    final all = await getAll(name);
    if (index < 0 || index >= all.length) return;
    final id = all[index]['_docId']?.toString();
    if (id == null) return;
    await delete(name, id);
  }

  static Future<int> count(String name) async {
    try {
      final snap = await col(name).count().get();
      return snap.count ?? 0;
    } catch (_) {
      return (await getAll(name)).length;
    }
  }

  static Future<Map<String, dynamic>?> getSingleton(
    String collection,
    String docId,
  ) async =>
      getDoc(collection, docId);

  static Future<void> setSingleton(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await set(collection, docId, data, merge: true);
  }

  static void log(String msg) => debugPrint('[Fs] $msg');
}

import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/welcome_media.dart';

class WelcomeMediaStorage {
  static const boxName = 'welcome_media';
  static const imagesBoxName = 'welcome_images';

  static Future<void> open() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    if (!Hive.isBoxOpen(imagesBoxName)) {
      await Hive.openBox(imagesBoxName);
    }
  }

  static Box get _box => Hive.box(boxName);
  static Box get _images => Hive.box(imagesBoxName);

  static List<WelcomeSlide> defaults() => [
        WelcomeSlide(
          id: '1',
          imageUrl:
              'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=1400&q=80',
          caption: 'Science in action',
          subtitle: 'Students learning through practical experiments',
        ),
        WelcomeSlide(
          id: '2',
          imageUrl:
              'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=1400&q=80',
          caption: 'Focused classrooms',
          subtitle: 'Engaged learners, guided by dedicated teachers',
        ),
        WelcomeSlide(
          id: '3',
          imageUrl:
              'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=1400&q=80',
          caption: 'Together we grow',
          subtitle: 'Collaboration, discipline and excellence',
        ),
        WelcomeSlide(
          id: '4',
          imageUrl:
              'https://images.unsplash.com/photo-1588072432836-e10032774350?w=1400&q=80',
          caption: 'Building futures',
          subtitle: 'Happy School — knowledge with character',
        ),
        WelcomeSlide(
          id: '5',
          imageUrl:
              'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1400&q=80',
          caption: 'Proud moments',
          subtitle: 'Celebrating achievement and hard work',
        ),
      ];

  static Future<List<WelcomeSlide>> getSlides() async {
    await open();
    if (_box.isEmpty) {
      final d = defaults();
      await saveAll(d);
      return d;
    }
    final list = <WelcomeSlide>[];
    for (final raw in _box.values) {
      try {
        list.add(WelcomeSlide.fromMap(Map<String, dynamic>.from(raw as Map)));
      } catch (_) {}
    }
    list.sort((a, b) => a.id.compareTo(b.id));
    if (list.isEmpty) return defaults();
    return list;
  }

  static Future<void> saveAll(List<WelcomeSlide> slides) async {
    await open();
    await _box.clear();
    for (final s in slides) {
      await _box.add(s.toMap());
    }
    await _box.flush();
  }

  /// Store raw bytes for a slide; returns imageKey to put on the slide.
  static Future<String> saveImageBytes(Uint8List bytes) async {
    await open();
    final key = 'img_${DateTime.now().millisecondsSinceEpoch}';
    await _images.put(key, bytes);
    await _images.flush();
    return key;
  }

  static Uint8List? getImageBytes(String? imageKey) {
    if (imageKey == null || imageKey.isEmpty) return null;
    if (!Hive.isBoxOpen(imagesBoxName)) return null;
    final raw = _images.get(imageKey);
    if (raw is Uint8List) return raw;
    if (raw is List) {
      try {
        return Uint8List.fromList(List<int>.from(raw));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> deleteImageKey(String? imageKey) async {
    if (imageKey == null || imageKey.isEmpty) return;
    await open();
    await _images.delete(imageKey);
  }

  static Future<WelcomeSlide> addSlide({
    required String caption,
    required String subtitle,
    String imageUrl = '',
    String imageKey = '',
  }) async {
    await open();
    final s = WelcomeSlide(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imageUrl: imageUrl.trim(),
      imageKey: imageKey.trim(),
      caption: caption.trim(),
      subtitle: subtitle.trim(),
    );
    await _box.add(s.toMap());
    await _box.flush();
    return s;
  }

  static Future<void> deleteAt(int index) async {
    await open();
    if (index < 0 || index >= _box.length) return;
    try {
      final raw = _box.getAt(index);
      if (raw is Map) {
        final key = raw['imageKey']?.toString();
        if (key != null && key.isNotEmpty) {
          await _images.delete(key);
        }
      }
    } catch (_) {}
    await _box.deleteAt(index);
    await _box.flush();
  }
}

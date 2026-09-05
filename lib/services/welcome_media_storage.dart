import 'dart:convert';
import 'dart:typed_data';

import '../core/school_profile_controller.dart';
import '../database/fs.dart';
import '../models/welcome_media.dart';

class WelcomeMediaStorage {
  static const boxName = 'welcome_media';
  static const imagesBoxName = 'welcome_images';
  static final Map<String, Uint8List> _imageCache = {};

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
          subtitle:
              '${SchoolProfileController.instance.name} — knowledge with character',
        ),
        WelcomeSlide(
          id: '5',
          imageUrl:
              'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=1400&q=80',
          caption: 'Proud moments',
          subtitle: 'Celebrating achievement and hard work',
        ),
      ];

  static Future<void> open() async {}

  static Future<List<WelcomeSlide>> getSlides() async {
    final rows = await Fs.getAll(boxName);
    if (rows.isEmpty) return defaults();
    final list = <WelcomeSlide>[];
    for (final r in rows) {
      try {
        list.add(WelcomeSlide.fromMap(Map<String, dynamic>.from(r)));
      } catch (_) {}
    }
    return list.isEmpty ? defaults() : list;
  }

  static Future<void> saveAll(List<WelcomeSlide> slides) async {
    for (final r in await Fs.getAll(boxName)) {
      final id = r['_docId']?.toString();
      if (id != null) await Fs.delete(boxName, id);
    }
    for (final s in slides) {
      await Fs.add(boxName, s.toMap());
    }
  }

  static Future<String> saveImageBytes(Uint8List bytes) async {
    final key = 'img_${DateTime.now().millisecondsSinceEpoch}';
    _imageCache[key] = bytes;
    await Fs.set(imagesBoxName, key, {'base64': base64Encode(bytes)});
    return key;
  }

  /// Sync read from memory cache (call prefetchImage first when possible).
  static Uint8List? getImageBytes(String? imageKey) {
    if (imageKey == null || imageKey.isEmpty) return null;
    return _imageCache[imageKey];
  }

  static Future<Uint8List?> prefetchImage(String? imageKey) async {
    if (imageKey == null || imageKey.isEmpty) return null;
    if (_imageCache.containsKey(imageKey)) return _imageCache[imageKey];
    final raw = await Fs.getDoc(imagesBoxName, imageKey);
    final b64 = raw?['base64']?.toString();
    if (b64 == null || b64.isEmpty) return null;
    try {
      final bytes = base64Decode(b64);
      _imageCache[imageKey] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteImageKey(String? imageKey) async {
    if (imageKey == null || imageKey.isEmpty) return;
    _imageCache.remove(imageKey);
    await Fs.delete(imagesBoxName, imageKey);
  }

  static Future<WelcomeSlide> addSlide({
    required String caption,
    required String subtitle,
    String imageUrl = '',
    String imageKey = '',
  }) async {
    final slide = WelcomeSlide(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      caption: caption,
      subtitle: subtitle,
      imageUrl: imageUrl,
      imageKey: imageKey,
    );
    await Fs.add(boxName, slide.toMap());
    return slide;
  }

  static Future<void> deleteAt(int index) async {
    await Fs.deleteAt(boxName, index);
  }
}

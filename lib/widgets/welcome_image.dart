import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/welcome_media_storage.dart';

class WelcomeImage extends StatelessWidget {
  final String source;
  final String imageKey;
  final BoxFit fit;

  const WelcomeImage({
    super.key,
    this.source = '',
    this.imageKey = '',
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageKey.trim().isNotEmpty) {
      final cached = WelcomeMediaStorage.getImageBytes(imageKey.trim());
      if (cached != null && cached.isNotEmpty) {
        return Image.memory(
          cached,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
      return FutureBuilder<Uint8List?>(
        future: WelcomeMediaStorage.prefetchImage(imageKey.trim()),
        builder: (context, snap) {
          final bytes = snap.data;
          if (bytes != null && bytes.isNotEmpty) {
            return Image.memory(
              bytes,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => _fallback(),
            );
          }
          if (snap.connectionState != ConnectionState.done) {
            return Container(
              color: const Color(0xFF0F172A),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            );
          }
          return _fromSource();
        },
      );
    }
    return _fromSource();
  }

  Widget _fromSource() {
    final s = source.trim();
    if (s.isEmpty) return _fallback();
    if (s.startsWith('data:image')) {
      try {
        final bytes = base64Decode(s.split(',').last);
        return Image.memory(bytes, fit: fit, width: double.infinity, height: double.infinity);
      } catch (_) {
        return _fallback();
      }
    }
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return Image.network(s, fit: fit, width: double.infinity, height: double.infinity,
          errorBuilder: (_, __, ___) => _fallback());
    }
    if (s.startsWith('assets/')) {
      return Image.asset(s, fit: fit, width: double.infinity, height: double.infinity,
          errorBuilder: (_, __, ___) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 40),
        ),
      );
}

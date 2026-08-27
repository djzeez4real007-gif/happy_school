import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/welcome_media_storage.dart';

/// Renders picked bytes (imageKey), data-URI, http(s), or asset — full bleed, sharp.
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
    // 1) Hive bytes (device pick)
    if (imageKey.trim().isNotEmpty) {
      final bytes = WelcomeMediaStorage.getImageBytes(imageKey.trim());
      if (bytes != null && bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => _fallback(),
        );
      }
    }

    final s = source.trim();
    if (s.isEmpty) return _fallback();

    if (s.startsWith('data:image')) {
      try {
        final b64 = s.split(',').last;
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => _fallback(),
        );
      } catch (_) {
        return _fallback();
      }
    }

    if (s.startsWith('http://') || s.startsWith('https://')) {
      return Image.network(
        s,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stack) => _fallback(),
        loadingBuilder: (context, child, prog) {
          if (prog == null) return child;
          return Container(
            color: const Color(0xFF0F172A),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        },
      );
    }

    if (s.startsWith('assets/')) {
      return Image.asset(
        s,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stack) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white38, size: 40),
            SizedBox(height: 8),
            Text(
              'Image could not load',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

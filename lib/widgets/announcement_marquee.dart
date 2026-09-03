import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

import '../models/announcement.dart';
import '../services/announcement_storage.dart';

/// Sliding NEWS bar — same data source as admin dashboard.
class AnnouncementMarquee extends StatefulWidget {
  const AnnouncementMarquee({super.key});

  @override
  State<AnnouncementMarquee> createState() => _AnnouncementMarqueeState();
}

class _AnnouncementMarqueeState extends State<AnnouncementMarquee>
    with SingleTickerProviderStateMixin {
  String _combined = '';
  bool loading = true;
  late final AnimationController _ctrl;
  double _textWidth = 280;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await AnnouncementStorage.getAnnouncements();
      list.sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.date.compareTo(a.date);
      });
      final parts = <String>[];
      for (final a in list) {
        final t = a.title.trim();
        final m = a.message.trim();
        if (t.isEmpty && m.isEmpty) continue;
        if (t.isNotEmpty && m.isNotEmpty) {
          parts.add('📢 $t — $m');
        } else if (t.isNotEmpty) {
          parts.add('📢 $t');
        } else {
          parts.add('📢 $m');
        }
      }
      if (!mounted) return;
      setState(() {
        _combined = parts.join('     •     ');
        loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startMarquee();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        _combined = '';
      });
    }
  }

  void _startMarquee() {
    if (!mounted || _combined.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: _combined,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    _textWidth = (tp.width + 80).clamp(200.0, 5000.0);
    final seconds = (_textWidth / 45).clamp(8.0, 90.0);
    _ctrl.stop();
    _ctrl
      ..duration = Duration(milliseconds: (seconds * 1000).round())
      ..repeat();
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(height: 8);
    }
    // Always show bar so user knows the slot exists; text if any
    final text = _combined.isEmpty
        ? '📢 No announcements yet — check back soon'
        : _combined;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'NEWS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final w = _textWidth;
                    final dx = _combined.isEmpty ? 0.0 : -_ctrl.value * w;
                    Widget line() => Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              text,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                    if (_combined.isEmpty) return line();
                    return Stack(
                      children: [
                        Transform.translate(
                            offset: Offset(dx, 0), child: line()),
                        Transform.translate(
                            offset: Offset(dx + w, 0), child: line()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

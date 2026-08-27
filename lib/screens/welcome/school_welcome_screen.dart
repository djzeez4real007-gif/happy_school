import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/welcome_media.dart';
import '../../services/welcome_media_storage.dart';
import '../../widgets/welcome_image.dart';
import '../auth/login_screen.dart';

class SchoolWelcomeScreen extends StatefulWidget {
  const SchoolWelcomeScreen({super.key});

  @override
  State<SchoolWelcomeScreen> createState() => _SchoolWelcomeScreenState();
}

class _SchoolWelcomeScreenState extends State<SchoolWelcomeScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final AnimationController _pulseCtrl;
  int _page = 0;
  Timer? _timer;
  List<WelcomeSlide> _slides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _loadSlides();
  }

  Future<void> _loadSlides() async {
    try {
      final all = await WelcomeMediaStorage.getSlides();
      final list = all.take(5).toList();
      if (!mounted) return;
      setState(() {
        _slides = list.isEmpty ? WelcomeMediaStorage.defaults() : list;
        _loading = false;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || _slides.isEmpty) return;
        final next = (_page + 1) % _slides.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slides = WelcomeMediaStorage.defaults();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _slides.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _slides.length,
            itemBuilder: (context, i) {
              final slide = _slides[i];
              // No Transform.scale — zoom was cropping the flyer edges.
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  // Same image, blurred + scaled, fills the wide screen
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                      child: Transform.scale(
                        scale: 1.15,
                        child: WelcomeImage(
                          source: slide.imageUrl,
                          imageKey: slide.imageKey,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
                  // Sharp full flyer on top (no crop)
                  Positioned.fill(
                    child: WelcomeImage(
                      source: slide.imageUrl,
                      imageKey: slide.imageKey,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Soft gradient only near the bottom for text readability
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.45, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideCtrl,
                  curve: Curves.easeOutCubic,
                )),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              image: const DecorationImage(
                                image: AssetImage(
                                    'assets/images/school_logo.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Happy School',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  'ERP System',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: Column(
                          key: ValueKey(_page),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _slides[_page].caption,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _slides[_page].subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(_slides.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            height: 4,
                            width: active ? 22 : 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 200,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: _goLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1D4ED8),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final narrow = c.maxWidth < 700;
                            final items = [
                              _hInfo(Icons.location_on_rounded, 'Address',
                                  'Bolakale St. Checking Point, Ilorin'),
                              _hInfo(Icons.phone_rounded, 'Contact',
                                  '07068791117'),
                              _hInfo(Icons.email_rounded, 'Email',
                                  'thehappyone2019@gmail.com'),
                              _hInfo(Icons.code_rounded, 'Developed by',
                                  'Happy Enterprise'),
                            ];
                            if (narrow) {
                              return Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: items
                                    .map((w) => SizedBox(
                                          width: (c.maxWidth - 12) / 2,
                                          child: w,
                                        ))
                                    .toList(),
                              );
                            }
                            return Row(
                              children: [
                                for (var i = 0; i < items.length; i++) ...[
                                  if (i > 0)
                                    Container(
                                      width: 1,
                                      height: 36,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      color: Colors.white24,
                                    ),
                                  Expanded(child: items[i]),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '© ${DateTime.now().year} Happy School · All Rights Reserved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

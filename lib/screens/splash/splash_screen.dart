import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/school_profile_controller.dart';
import '../../core/school_branding.dart';
import '../../../core/theme/app_colors.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_shell.dart';
import '../auth/login_screen.dart';
import '../welcome/school_welcome_screen.dart' show SchoolWelcomeScreen;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  late final AnimationController _progress;

  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _progressValue;

  bool _logoReady = false;
  bool _logoFailed = false;

  static const String _logoAsset = 'assets/images/school_logo.png';

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.55),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _progressValue = CurvedAnimation(
      parent: _progress,
      curve: Curves.easeInOutCubic,
    );

    _prepareAndStart();
  }

  Future<void> _prepareAndStart() async {
    // Wait one frame so context is ready for precache
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    try {
      try {
        await precacheImage(SchoolBranding.logoProvider(), context);
      } catch (_) {
        try {
          await precacheImage(const AssetImage(_logoAsset), context);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _logoReady = true;
        _logoFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _logoReady = true;
        _logoFailed = true;
      });
    }

    _entrance.forward();
    _progress.forward();

    await Future<void>.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    _goNext();
  }

  void _goNext() {
    if (!mounted) return;

    final next = AuthService.isLoggedIn
        ? const AppShell()
        : const SchoolWelcomeScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    _progress.dispose();
    super.dispose();
  }

  Widget _buildLogo() {
    // Same approach as login — DecorationImage is reliable on web
    return ScaleTransition(
      scale: _logoScale,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
          image: _logoFailed
              ? null
              : DecorationImage(
                  image: SchoolBranding.logoProvider(),
                  fit: BoxFit.cover,
                ),
        ),
        child: _logoFailed
            ? Icon(
                Icons.school_rounded,
                size: 60,
                color: AppColors.primary,
              )
            : (!_logoReady
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF071433),
                    const Color(0xFF0F2A6B),
                    AppColors.primary,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SplashPatternPainter(progress: _pulse.value),
                );
              },
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final scale = 1 + (_pulse.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),

                    const SizedBox(height: 36),

                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              SchoolProfileController.instance.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 56,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF93C5FD),
                                    Color(0xFFFFFFFF),
                                    Color(0xFF93C5FD),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'School Management System',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Excellence · Integrity · Knowledge',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 56),

                    FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          SizedBox(
                            width: math.min(size.width * 0.45, 200),
                            child: AnimatedBuilder(
                              animation: _progressValue,
                              builder: (context, _) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: _progressValue.value,
                                    minHeight: 4,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.15),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Preparing your workspace…',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: FadeTransition(
              opacity: _textFade,
              child: Text(
                'Version 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11.5,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashPatternPainter extends CustomPainter {
  final double progress;

  _SplashPatternPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05);

    const step = 52.0;
    final shift = progress * 10;
    for (double x = -step + shift; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -step - shift; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.06);

    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.18),
      80 + progress * 6,
      glow,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.82),
      110 + progress * 8,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

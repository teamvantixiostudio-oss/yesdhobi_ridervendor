import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yesdhobi_ridervendor/widgets/app_logo.dart';
import 'package:yesdhobi_ridervendor/screens/portal_selection_screen.dart';
import 'package:yesdhobi_ridervendor/screens/rider_dashboard_screen.dart';
import 'package:yesdhobi_ridervendor/screens/vendor_home_screen.dart';
import 'package:yesdhobi_ridervendor/services/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutQuad),
    );

    _entranceController.forward();

    _navTimer = Timer(const Duration(milliseconds: 2600), _resumeOrSignIn);
  }

  /// Send an already-signed-in partner straight back to their portal.
  ///
  /// This screen used to go to portal selection unconditionally, so closing the
  /// app - or just letting Android reclaim it - meant logging in again every
  /// single time, even though the tokens were sitting in storage. ApiClient
  /// keeps the access token and which portal it belongs to; we just have to ask.
  Future<void> _resumeOrSignIn() async {
    Widget destination = const PortalSelectionScreen();
    try {
      await ApiClient.instance.init();
      if (ApiClient.instance.isAuthenticated) {
        destination = ApiClient.instance.activeRole == 'VENDOR'
            ? const VendorHomeScreen()
            : const RiderDashboardScreen();
      }
    } catch (e) {
      debugPrint('Could not restore the saved session: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _entranceController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.25,
                  colors: [
                    Color(0xFF132A6B),
                    Color(0xFF0C1638),
                    Color(0xFF070B19),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Animated water ripple rings behind logo
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, _) {
                final double r1 = _rippleAnimation.value;
                final double r2 = (r1 + 0.5) % 1.0;
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140 + (r1 * 130),
                        height: 140 + (r1 * 130),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00D2B4)
                                .withValues(alpha: (1.0 - r1) * 0.28),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 140 + (r2 * 130),
                        height: 140 + (r2 * 130),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF5A72F6)
                                .withValues(alpha: (1.0 - r2) * 0.22),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Main Center Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Elevated Frosted Glass Emblem Badge
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D2B4).withValues(alpha: 0.28),
                          blurRadius: 36,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: YesDhobiEmblemMark(
                        size: 64,
                        waveColor: const Color(0xFF00D2B4),
                        dropColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Official Yes Dhobi Logotype (White variant for dark background)
                  const YesDhobiLogo(
                    height: 40,
                    variant: LogoVariant.white,
                  ),

                  const SizedBox(height: 14),

                  // Portal Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2B4).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00D2B4).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'PARTNER PORTAL • RIDER & VENDOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00D2B4),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom Brand Tech credit
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D2B4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Powered by Yes Dhobi Platform',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

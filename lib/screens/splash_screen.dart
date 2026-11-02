import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/brand.dart';
import '../data/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final CurvedAnimation _reveal = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
  );
  late final CurvedAnimation _logoReveal = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _logoScale = Tween<double>(
    begin: 0.94,
    end: 1,
  ).animate(_logoReveal);
  late final CurvedAnimation _taglineReveal = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.38, 0.92, curve: Curves.easeOutCubic),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final imageReady = precacheImage(
      const AssetImage('assets/brand/feriwala_cycle_vendor.png'),
      context,
    ).catchError((_) {});
    _start(reduceMotion, imageReady);
  }

  Future<void> _start(bool reduceMotion, Future<void> imageReady) async {
    final shop = context.read<Shop>();
    if (reduceMotion) {
      _intro.value = 1;
    } else {
      try {
        await Future.wait<void>([imageReady, _intro.forward().orCancel]);
      } on TickerCanceled {
        return;
      }
    }
    while (mounted && !shop.ready) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    final Widget page = !shop.onboarded
        ? const OnboardingScreen()
        : shop.userName == null
        ? const AuthScreen()
        : const Shell();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoReveal.dispose();
    _taglineReveal.dispose();
    _reveal.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _reveal,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.015),
                    end: Offset.zero,
                  ).animate(_reveal),
                  child: RepaintBoundary(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _logoScale,
                          child: CycleVendorLogo(
                            width: MediaQuery.sizeOf(context).width * 0.82,
                            height:
                                MediaQuery.sizeOf(context).width * 0.82 / 1.62,
                            travel: 6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const FittedBox(child: BrandWordmark(size: 40)),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _taglineReveal,
                          child: Text(
                            Brand.banglaTagline,
                            textAlign: TextAlign.center,
                            style: Txt.bangla.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lavender,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
            left: 24,
            right: 24,
            child: Text(
              Brand.tagline,
              textAlign: TextAlign.center,
              style: Txt.small.copyWith(color: AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }
}

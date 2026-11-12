/// MODULE: Onboarding screen — Three swipeable intro pages with 3D orbiting
/// icons, shown on first launch only.
///
/// Contains: OnboardPage, OnboardingScreen, _OnboardingScreenState,
/// OrbitIllustration, _OrbitIllustrationState.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/config/brand_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/state/shop_state.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/auth_screen.dart';

class OnboardPage {
  final String title, body;
  final IconData center;
  final List<IconData> orbit;
  final Color accent;
  const OnboardPage(
    this.title,
    this.body,
    this.center,
    this.orbit,
    this.accent,
  );
}

final _pages = [
  OnboardPage(
    'Shop the whole\nuniverse',
    'Phones, gadgets, fashion and beauty — over 200 hand-picked products in one place.',
    Iconsax.shopping_bag,
    [
      Iconsax.mobile,
      Iconsax.watch,
      Iconsax.headphone,
      Iconsax.glass,
      Iconsax.bag_2,
      Iconsax.lamp,
    ],
    AppColors.violetLight,
  ),
  OnboardPage(
    'Deals at the\nspeed of light',
    'Flash sales every day, up to 25% off, plus vouchers that stack at checkout.',
    Iconsax.flash,
    [
      Iconsax.discount_shape,
      Iconsax.ticket_discount,
      Iconsax.gift,
      Iconsax.timer,
      Iconsax.crown,
    ],
    AppColors.magenta,
  ),
  OnboardPage(
    'Pay your way,\ndelivered fast',
    'bKash, Nagad, card or cash on delivery. Free delivery over ${taka(Brand.freeDeliveryOver)} across Bangladesh.',
    Iconsax.truck_fast,
    [
      Iconsax.wallet,
      Iconsax.card,
      Iconsax.money,
      Iconsax.location,
      Iconsax.shield_tick,
    ],
    AppColors.cyan,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _page = _pc.page ?? 0));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<Shop>().finishOnboarding();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final last = _page > _pages.length - 1.5;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(
                children: [
                  const BrandWordmark(size: 22),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  final delta = (_page - i).clamp(-1.0, 1.0);
                  return Column(
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(delta * 120, 0),
                          child: Opacity(
                            opacity: (1 - delta.abs()).clamp(0.0, 1.0),
                            child: Center(child: OrbitIllustration(page: p)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Transform.translate(
                          offset: Offset(delta * -60, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GradientText(
                                p.title,
                                style: Txt.h1.copyWith(fontSize: 34),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                p.body,
                                style: Txt.body.copyWith(
                                  color: AppColors.textDim,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Row(
                children: [
                  SmoothPageIndicator(
                    controller: _pc,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                      spacing: 6,
                      activeDotColor: AppColors.violetLight,
                      dotColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const Spacer(),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    child: GlowButton(
                      expanded: false,
                      label: last ? 'Get started' : 'Next',
                      icon: last ? Iconsax.arrow_right_3 : null,
                      onTap: () => last
                          ? _finish()
                          : _pc.nextPage(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A glowing glass planet with icons orbiting on a tilted 3D ellipse —
/// items in front grow and brighten, items behind shrink and dim.
class OrbitIllustration extends StatefulWidget {
  final OnboardPage page;
  const OrbitIllustration({super.key, required this.page});

  @override
  State<OrbitIllustration> createState() => _OrbitIllustrationState();
}

class _OrbitIllustrationState extends State<OrbitIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!animate) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.page;
    return LayoutBuilder(
      builder: (context, box) {
        final s = math.min(box.maxWidth, box.maxHeight) * 0.92;
        return SizedBox.square(
          dimension: s,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final items = <(double depth, Widget w)>[];
              final n = p.orbit.length;
              for (var i = 0; i < n; i++) {
                final a = (_c.value + i / n) * math.pi * 2;
                final x = math.cos(a) * s * 0.42;
                final z = math.sin(a); // -1 back .. 1 front
                final y = z * s * 0.13 - x * 0.18;
                final scale = 0.7 + 0.35 * (z + 1) / 2;
                items.add((
                  z,
                  Transform.translate(
                    offset: Offset(x, y),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: 0.45 + 0.55 * (z + 1) / 2,
                        child: Glass(
                          radius: 20,
                          blur: 8,
                          opacity: 0.12,
                          child: SizedBox.square(
                            dimension: 58,
                            child: Icon(
                              p.orbit[i],
                              color: Color.lerp(Colors.white, p.accent, 0.5),
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ));
              }
              items.sort((a, b) => a.$1.compareTo(b.$1));
              final back = items.where((e) => e.$1 < 0).map((e) => e.$2);
              final front = items.where((e) => e.$1 >= 0).map((e) => e.$2);
              return Stack(
                alignment: Alignment.center,
                children: [
                  // glow
                  Container(
                    width: s * 0.8,
                    height: s * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          p.accent.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // ring
                  Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      width: s * 0.92,
                      height: s * 0.3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(s * 0.46, s * 0.15),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                  ...back,
                  // planet
                  Transform.translate(
                    offset: Offset(0, math.sin(_c.value * math.pi * 4) * 6),
                    child: Container(
                      width: s * 0.38,
                      height: s * 0.38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(p.accent, Colors.white, 0.25)!,
                            AppColors.violet,
                            const Color(0xFF3B0764),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.6),
                            blurRadius: 60,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.25),
                            blurRadius: 2,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        p.center,
                        size: s * 0.15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ...front,
                ],
              );
            },
          ),
        );
      },
    );
  }
}

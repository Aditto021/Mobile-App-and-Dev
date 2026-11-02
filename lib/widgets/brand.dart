import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/brand.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

/// The FeriWala cycle vendor, gently gliding on the splash screen only.
class CycleVendorLogo extends StatefulWidget {
  final double width;
  final double height;
  final double travel;

  const CycleVendorLogo({
    super.key,
    required this.width,
    required this.height,
    this.travel = 7,
  });

  @override
  State<CycleVendorLogo> createState() => _CycleVendorLogoState();
}

class _CycleVendorLogoState extends State<CycleVendorLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionAllowed =
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        TickerMode.of(context);
    if (motionAllowed && !_motion.isAnimating) {
      _motion.repeat(reverse: true);
    } else if (!motionAllowed && _motion.isAnimating) {
      _motion.stop();
      _motion.value = 0.5;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'FeriWala cycle vendor logo',
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, child) {
            final t = Curves.easeInOutSine.transform(_motion.value);
            // One restrained arc per pass keeps the bicycle's glide calm and
            // avoids the repeated bobble caused by a full sine wave.
            final bob = math.sin(t * math.pi);
            return Transform.translate(
              offset: Offset(
                (t - 0.5) * 2 * widget.travel,
                -bob * 1.4,
              ),
              child: Transform.rotate(
                angle: -bob * 0.003,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.magenta.withValues(alpha: 0.18),
                        AppColors.cyan.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.52, 1],
                    ),
                  ),
                ),
                Image.asset(
                  'assets/brand/feriwala_cycle_vendor.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app mark: a glowing glass orb holding a shopping bag, circled by
/// an orbit ring with a travelling "planet".
class BrandMark extends StatefulWidget {
  final double size;
  final bool spin;
  const BrandMark({super.key, this.size = 64, this.spin = false});

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.spin &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: BrandMarkPainter(_c.value),
        ),
      ),
    );
  }
}

class BrandMarkPainter extends CustomPainter {
  final double t;
  final bool background;
  BrandMarkPainter(this.t, {this.background = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);

    if (background) {
      final r = Offset.zero & size;
      canvas.drawRect(
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            radius: 1.2,
            colors: [Color(0xFF2A1260), Color(0xFF0B0518)],
          ).createShader(r),
      );
    }

    // Outer glow
    canvas.drawCircle(
      c,
      s * 0.46,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.violet.withValues(alpha: 0.55),
            AppColors.violet.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: s * 0.46)),
    );

    // Orb
    final orbR = s * 0.30;
    final orbRect = Rect.fromCircle(center: c, radius: orbR);
    canvas.drawCircle(
      c,
      orbR,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFC026D3)],
        ).createShader(orbRect),
    );
    // Specular highlight
    canvas.drawCircle(
      c + Offset(-orbR * 0.35, -orbR * 0.4),
      orbR * 0.75,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: c + Offset(-orbR * 0.35, -orbR * 0.4),
                radius: orbR * 0.75,
              ),
            ),
    );
    canvas.drawCircle(
      c,
      orbR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Shopping bag glyph
    final bw = orbR * 0.95, bh = orbR * 0.82;
    final bag = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: c + Offset(0, orbR * 0.14),
        width: bw,
        height: bh,
      ),
      Radius.circular(s * 0.035),
    );
    final white = Paint()..color = Colors.white;
    canvas.drawRRect(bag, white);
    final handle = Path()
      ..addArc(
        Rect.fromCenter(
          center: c + Offset(0, -bh * 0.30),
          width: bw * 0.52,
          height: bh * 0.62,
        ),
        math.pi,
        math.pi,
      );
    canvas.drawPath(
      handle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.03
        ..color = Colors.white,
    );
    // Smile on the bag
    final smile = Path()
      ..addArc(
        Rect.fromCenter(
          center: c + Offset(0, orbR * 0.12),
          width: bw * 0.42,
          height: bh * 0.34,
        ),
        0.15,
        math.pi - 0.3,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.028
        ..color = const Color(0xFF9333EA),
    );

    // Orbit ring (tilted ellipse)
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.42);
    final ring = Rect.fromCenter(
      center: Offset.zero,
      width: s * 0.86,
      height: s * 0.30,
    );
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.016
      ..shader = const SweepGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0xCCF0ABFC),
          Color(0xFFFFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(ring);
    // Back half of ring (behind orb would need layering; draw full ring
    // with the lower arc on top to fake depth)
    canvas.drawArc(ring, 0, math.pi, false, ringPaint);
    final a = t * math.pi * 2;
    final planet = Offset(
      math.cos(a) * ring.width / 2,
      math.sin(a) * ring.height / 2,
    );
    if (math.sin(a) >= 0) {
      canvas.drawCircle(planet, s * 0.045, Paint()..color = Colors.white);
      canvas.drawCircle(
        planet,
        s * 0.09,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.magenta.withValues(alpha: 0.8),
              AppColors.magenta.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: planet, radius: s * 0.09)),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BrandMarkPainter old) => old.t != t;
}

/// Word mark: [Brand.wordmarkMain] + [Brand.wordmarkSuffix].
class BrandWordmark extends StatelessWidget {
  final double size;
  const BrandWordmark({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        GradientText(
          Brand.wordmarkMain,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.6,
          ),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFE9D5FF), Color(0xFFF0ABFC)],
          ),
        ),
        Text(
          Brand.wordmarkSuffix,
          style: TextStyle(
            fontSize: size * 0.62,
            fontWeight: FontWeight.w600,
            color: AppColors.violetLight,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

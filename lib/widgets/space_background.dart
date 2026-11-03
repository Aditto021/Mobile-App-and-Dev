import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_theme.dart';

/// Global parallax signal. Scroll views nudge this so the nebula drifts
/// with the content, giving the whole app a sense of depth.
final ValueNotifier<Offset> nebulaParallax = ValueNotifier(Offset.zero);

/// When true the nebula drifts gently behind the catalogue. The effect is
/// intentionally restrained and capped at 30 fps so products remain the focus.
final ValueNotifier<bool> liveNebula = ValueNotifier(false);

/// How much taller than the screen the baked image is, so parallax can
/// slide it without revealing an edge.
const _parallaxSlack = 0.12;

/// Draws the GPU nebula shader behind the entire app.
///
/// Default mode bakes one frame of the shader into an image (once per
/// screen size) and just blits it — effectively free per frame. Live mode
/// runs the shader every other frame. Falls back to a painted gradient +
/// starfield if shaders are unavailable.
class SpaceBackground extends StatefulWidget {
  final Widget child;
  const SpaceBackground({super.key, required this.child});

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  ui.Image? _baked;
  Size? _bakedFor;
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(12);
  Duration _lastPaint = Duration.zero;
  bool _reduceMotion = false;
  bool _shaderLoading = false;
  bool get _isLive => liveNebula.value && !_reduceMotion;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      // Slow atmospheric motion does not need to update at display refresh.
      if (elapsed - _lastPaint < const Duration(milliseconds: 33)) return;
      _lastPaint = elapsed;
      _time.value = 12 + elapsed.inMicroseconds / 1e6;
    });
    liveNebula.addListener(_onLiveChanged);
    _onLiveChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      _onLiveChanged();
    }
  }

  void _onLiveChanged() {
    if (_isLive) {
      if (_shader == null && !_shaderLoading) _loadShader();
      if (!_ticker.isActive) _ticker.start();
    } else {
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadShader() async {
    _shaderLoading = true;
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/nebula.frag');
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (e) {
      debugPrint('Nebula shader unavailable, using fallback: $e');
    } finally {
      _shaderLoading = false;
    }
  }

  /// Renders one still frame of the shader into an image. 1.5 px per
  /// logical px keeps stars crisp while being ~4x cheaper than full res.
  void _bake(Size logical) {
    final shader = _shader;
    if (shader == null || logical.isEmpty) return;
    _bakedFor = logical;
    const density = 1.5;
    final w = (logical.width * density).round();
    final h = (logical.height * (1 + _parallaxSlack) * density).round();
    shader
      ..setFloat(0, w.toDouble())
      ..setFloat(1, h.toDouble())
      ..setFloat(2, 12)
      ..setFloat(3, 0)
      ..setFloat(4, 0)
      ..setFloat(5, 1);
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..shader = shader,
    );
    rec.endRecording().toImage(w, h).then((img) {
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() {
        _baked?.dispose();
        _baked = img;
      });
    });
  }

  @override
  void dispose() {
    liveNebula.removeListener(_onLiveChanged);
    _ticker.dispose();
    _shader?.dispose();
    _baked?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (_shader != null && !_isLive && _bakedFor != size) {
      _bake(size);
    }
    final CustomPainter painter;
    if (_shader != null && _isLive) {
      painter = _LivePainter(_shader!, _time);
    } else if (_baked != null) {
      painter = _BakedPainter(_baked!, reducedMotion: _reduceMotion);
    } else {
      painter = const _FallbackPainter();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.void1),
        RepaintBoundary(
          child: CustomPaint(painter: painter, size: Size.infinite),
        ),
        // Keep the space treatment atmospheric rather than decorative: the
        // catalogue stays dominant while a little colour and starlight remain.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.24, 0.66, 1],
              colors: [
                Color(0x3A090812),
                Color(0x680D0B18),
                Color(0x790A0A14),
                Color(0x68090A13),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: const Opacity(
              opacity: 0.14,
              child: CustomPaint(painter: _RickshawArtPainter()),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Very restrained nod to the floral scrollwork and jewel colours of
/// Bangladeshi rickshaw painting. Kept to the outer edges so the catalogue
/// remains the visual focus.
class _RickshawArtPainter extends CustomPainter {
  const _RickshawArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.shortestSide / 10).clamp(28.0, 42.0);
    _motif(
      canvas,
      Offset(size.width - scale * 0.48, size.height * 0.19),
      scale,
      const Color(0xFFF3C98B),
      const Color(0xFFED7AAE),
      flip: true,
    );
    _motif(
      canvas,
      Offset(scale * 0.48, size.height * 0.73),
      scale * 0.82,
      const Color(0xFF65D5CF),
      const Color(0xFFB77AF0),
    );
  }

  void _motif(
    Canvas canvas,
    Offset origin,
    double unit,
    Color leafColor,
    Color flowerColor, {
    bool flip = false,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (flip) canvas.scale(-1, 1);

    final lineColor = const Color(0xFFF3C98B).withValues(alpha: 0.18);
    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final vine = Path()
      ..moveTo(0, unit * 1.9)
      ..cubicTo(
        -unit * 0.35,
        unit * 1.15,
        unit * 0.1,
        unit * 0.85,
        -unit * 0.2,
        unit * 0.35,
      )
      ..cubicTo(
        -unit * 0.52,
        -unit * 0.1,
        -unit * 0.02,
        -unit * 0.2,
        unit * 0.08,
        -unit * 0.72,
      )
      ..cubicTo(
        unit * 0.18,
        -unit * 1.25,
        -unit * 0.38,
        -unit * 1.5,
        -unit * 0.7,
        -unit * 1.36,
      );
    canvas.drawPath(vine, line);

    _leaf(canvas, Offset(-unit * 0.24, unit * 0.43), -0.85, unit, leafColor);
    _leaf(canvas, Offset(-unit * 0.15, -unit * 0.12), 0.78, unit, flowerColor);
    _leaf(canvas, Offset(-unit * 0.1, unit * 1.02), -0.8, unit, flowerColor);
    _flower(
      canvas,
      Offset(-unit * 0.69, -unit * 1.35),
      unit * 0.24,
      flowerColor,
    );
    _flower(canvas, Offset(-unit * 0.18, unit * 0.35), unit * 0.31, leafColor);

    final dot = Paint()..color = lineColor.withValues(alpha: 0.72);
    for (final point in [
      Offset(unit * 0.22, -unit * 0.72),
      Offset(unit * 0.3, unit * 0.42),
      Offset(-unit * 0.55, unit * 0.96),
    ]) {
      canvas.drawCircle(point, 1.6, dot);
      final diamond = Path()
        ..moveTo(point.dx, point.dy - 4)
        ..lineTo(point.dx + 3, point.dy)
        ..lineTo(point.dx, point.dy + 4)
        ..lineTo(point.dx - 3, point.dy)
        ..close();
      canvas.drawPath(
        diamond,
        Paint()
          ..color = lineColor.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.restore();
  }

  void _leaf(
    Canvas canvas,
    Offset center,
    double angle,
    double unit,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final shape = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -unit * 0.17),
        width: unit * 0.15,
        height: unit * 0.38,
      ),
      Radius.circular(unit * 0.09),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..color = color.withValues(alpha: 0.07)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..color = color.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(0, -unit * 0.32),
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..strokeWidth = 0.7,
    );
    canvas.restore();
  }

  void _flower(Canvas canvas, Offset center, double radius, Color color) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.95;
    final fill = Paint()..color = color.withValues(alpha: 0.045);
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 4);
      final petal = Rect.fromCenter(
        center: Offset(0, -radius * 0.67),
        width: radius * 0.56,
        height: radius * 0.74,
      );
      canvas.drawOval(petal, fill);
      canvas.drawOval(petal, stroke);
      canvas.restore();
    }
    canvas.drawCircle(center, radius * 0.17, fill);
    canvas.drawCircle(center, radius * 0.17, stroke);
  }

  @override
  bool shouldRepaint(covariant _RickshawArtPainter oldDelegate) => false;
}

class _BakedPainter extends CustomPainter {
  final ui.Image image;
  final bool reducedMotion;
  _BakedPainter(this.image, {this.reducedMotion = false})
    : super(repaint: reducedMotion ? null : nebulaParallax);

  @override
  void paint(Canvas canvas, Size size) {
    final slack = size.height * _parallaxSlack;
    final dy =
        -(reducedMotion ? 0.0 : nebulaParallax.value.dy * 0.15).clamp(
          0.0,
          1.0,
        ) *
        slack;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, dy, size.width, size.height + slack),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _BakedPainter old) =>
      old.image != image || old.reducedMotion != reducedMotion;
}

class _LivePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ValueNotifier<double> time;
  _LivePainter(this.shader, this.time)
    : super(repaint: Listenable.merge([time, nebulaParallax]));

  @override
  void paint(Canvas canvas, Size size) {
    final p = nebulaParallax.value;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time.value)
      ..setFloat(3, p.dx)
      ..setFloat(4, p.dy)
      ..setFloat(5, 0.55);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _LivePainter old) => old.shader != shader;
}

class _FallbackPainter extends CustomPainter {
  const _FallbackPainter();

  static final _stars = List.generate(64, (i) {
    final r = math.Random(i * 31 + 7);
    return (Offset(r.nextDouble(), r.nextDouble()), r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080313), Color(0xFF150930)],
        ).createShader(rect),
    );
    void orb(Offset c, double r, Color col) => canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    orb(
      Offset(size.width * 0.25, size.height * 0.2),
      size.width * 0.8,
      AppColors.violet.withValues(alpha: 0.20),
    );
    orb(
      Offset(size.width * 0.9, size.height * 0.7),
      size.width * 0.7,
      AppColors.magenta.withValues(alpha: 0.10),
    );
    final paint = Paint();
    for (final (o, s) in _stars) {
      paint.color = Colors.white.withValues(alpha: 0.04 + 0.12 * s);
      canvas.drawCircle(
        Offset(o.dx * size.width, o.dy * size.height),
        0.4 + s * 0.65,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wrap a scrollable to feed its offset into the nebula parallax.
class ParallaxScroll extends StatelessWidget {
  final Widget child;
  const ParallaxScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (n) {
        if (!MediaQuery.disableAnimationsOf(context) &&
            !MediaQuery.accessibleNavigationOf(context) &&
            n.metrics.axis == Axis.vertical &&
            n.depth == 0) {
          nebulaParallax.value = Offset(0, n.metrics.pixels / 900);
        }
        return false;
      },
      child: child,
    );
  }
}

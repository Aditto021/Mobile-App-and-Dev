/// MODULE: Order success screen — Animated checkmark and confetti after an
/// order is placed, with the order summary.
///
/// Contains: OrderSuccessScreen, _OrderSuccessScreenState, _CheckPainter.
library;

import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../orders/orders_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Order order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  late final AnimationController _check = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _check.value = 1;
      return;
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _check.forward();
      HapticFeedback.heavyImpact();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _check,
                    builder: (_, _) => CustomPaint(
                      size: const Size.square(170),
                      painter: _CheckPainter(_check.value),
                    ),
                  ),
                  const SizedBox(height: 26),
                  GradientText(
                        'Order placed!',
                        style: Txt.h1.copyWith(fontSize: 32),
                      )
                      .animate()
                      .fadeIn(delay: 900.ms)
                      .slideY(begin: 0.4, curve: Curves.easeOutCubic),
                  const SizedBox(height: 8),
                  Text(
                    'Sit back — your order is on its way across the galaxy.',
                    textAlign: TextAlign.center,
                    style: Txt.body.copyWith(color: AppColors.textDim),
                  ).animate().fadeIn(delay: 1050.ms),
                  const SizedBox(height: 28),
                  Glass(
                        radius: 26,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _row(Iconsax.receipt_item, 'Order ID', '#${o.id}'),
                            _row(Iconsax.wallet_2, 'Payment', o.payment),
                            _row(Iconsax.money, 'Total', taka(o.total)),
                            _row(Iconsax.truck_fast, 'Arrives', _eta()),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 1200.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                  const Spacer(),
                  GlowButton(
                    label: 'Track my order',
                    icon: Iconsax.location,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    ),
                  ).animate().fadeIn(delay: 1400.ms),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Continue shopping',
                      style: TextStyle(color: AppColors.violetLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 26,
              maxBlastForce: 28,
              minBlastForce: 8,
              gravity: 0.18,
              colors: const [
                AppColors.violetLight,
                AppColors.magenta,
                AppColors.gold,
                AppColors.cyan,
                Colors.white,
              ],
              createParticlePath: _star,
            ),
          ),
        ],
      ),
    );
  }

  String _eta() {
    final d = DateTime.now().add(const Duration(days: 2));
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  Widget _row(IconData i, String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(i, size: 19, color: AppColors.violetLight),
        const SizedBox(width: 10),
        Text(l, style: TextStyle(color: AppColors.textDim)),
        const Spacer(),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  static Path _star(Size size) {
    final path = Path();
    final r = size.width / 2;
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = i * math.pi / 5 - math.pi / 2;
      final p = Offset(r + rr * math.cos(a), r + rr * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}

/// Glowing ring that draws itself, then a checkmark stroke, then a pulse.
class _CheckPainter extends CustomPainter {
  final double t;
  _CheckPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.38;
    final ringT = Curves.easeOutCubic.transform((t / 0.5).clamp(0.0, 1.0));
    final checkT = Curves.easeOutCubic.transform(
      ((t - 0.45) / 0.35).clamp(0.0, 1.0),
    );
    final pulseT = ((t - 0.7) / 0.3).clamp(0.0, 1.0);

    // pulse
    if (pulseT > 0) {
      canvas.drawCircle(
        c,
        r * (1 + pulseT * 0.35),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.magenta.withValues(alpha: (1 - pulseT) * 0.8),
      );
    }
    // filled disc
    canvas.drawCircle(
      c,
      r * ringT,
      Paint()
        ..shader = AppColors.brandGradient.createShader(
          Rect.fromCircle(center: c, radius: r),
        )
        ..color = Colors.white,
    );
    canvas.drawCircle(
      c,
      r * ringT,
      Paint()
        ..color = AppColors.violet.withValues(alpha: 0.6 * ringT)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 26),
    );
    // ring arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r + 10),
      -math.pi / 2,
      math.pi * 2 * ringT,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.6),
    );
    // check
    if (checkT > 0) {
      final path = Path()
        ..moveTo(c.dx - r * 0.42, c.dy + r * 0.02)
        ..lineTo(c.dx - r * 0.1, c.dy + r * 0.34)
        ..lineTo(c.dx + r * 0.46, c.dy - r * 0.3);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * checkT),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.t != t;
}

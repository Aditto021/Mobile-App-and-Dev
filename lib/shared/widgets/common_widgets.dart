/// MODULE: Common widgets — Small reusable pieces: top bar, animated counter,
/// quantity stepper, empty state, orbit rings and toast messages.
///
/// Contains: TopBar, AnimatedCount, QtyStepper, EmptyState, OrbitRings,
/// _OrbitRingsState, _OrbitPainter.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_theme.dart';
import 'glass_widgets.dart';

Future<T?> go<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// Top bar for pushed screens: glass back button, title, actions.
class TopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool back;
  const TopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.back = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        8,
      ),
      child: Row(
        children: [
          if (back) ...[
            GlassIconButton(
              icon: Iconsax.arrow_left_2,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Txt.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Txt.small.copyWith(color: AppColors.textDim),
                  ),
              ],
            ),
          ),
          for (final a in actions)
            Padding(padding: const EdgeInsets.only(left: 10), child: a),
        ],
      ),
    );
  }
}

/// Number that rolls smoothly to its new value.
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String Function(int) format;
  final Gradient? gradient;
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    required this.format,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 280,
      ),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) {
        final s = format(v.round());
        return gradient == null
            ? Text(s, style: style)
            : GradientText(s, style: style, gradient: gradient!);
      },
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  final double size;
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onChanged,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, int d) => Pressable(
      scale: 0.8,
      onTap: () => onChanged(qty + d),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(size * 0.35),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(i, size: size * 0.5),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_rounded, -1),
        SizedBox(
          width: size * 1.1,
          child: AnimatedSwitcher(
            duration: Duration(
              milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 160,
            ),
            transitionBuilder: (c, a) => SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(a),
              child: FadeTransition(opacity: a, child: c),
            ),
            child: Text(
              '$qty',
              key: ValueKey(qty),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size * 0.48,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        btn(Icons.add_rounded, 1),
      ],
    );
  }
}

/// Empty state with a floating glass orb illustration.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.void2,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(icon, size: 36, color: AppColors.lavender),
            ),
            const SizedBox(height: 22),
            Text(title, style: Txt.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: Txt.body.copyWith(color: AppColors.textDim),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 26),
              GlowButton(label: action!, onTap: onAction, expanded: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Slowly rotating dashed orbit rings with small satellites.
class OrbitRings extends StatefulWidget {
  final double size;
  const OrbitRings({super.key, required this.size});

  @override
  State<OrbitRings> createState() => _OrbitRingsState();
}

class _OrbitRingsState extends State<OrbitRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _OrbitPainter(_c.value),
      ),
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  final double t;
  _OrbitPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    for (var k = 0; k < 2; k++) {
      final rr = r * (k == 0 ? 0.98 : 0.74);
      final dir = k == 0 ? 1 : -1;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: k == 0 ? 0.14 : 0.22);
      const dashes = 48;
      for (var i = 0; i < dashes; i += 2) {
        final a0 = (i / dashes + t * dir) * math.pi * 2;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: rr),
          a0,
          math.pi * 2 / dashes,
          false,
          p,
        );
      }
      final a = (t * dir * 2 + k * 0.4) * math.pi * 2;
      final sat = c + Offset(math.cos(a), math.sin(a)) * rr;
      canvas.drawCircle(
        sat,
        4,
        Paint()..color = k == 0 ? AppColors.magenta : AppColors.cyan,
      );
      canvas.drawCircle(
        sat,
        10,
        Paint()
          ..color = (k == 0 ? AppColors.magenta : AppColors.cyan).withValues(
            alpha: 0.25,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.t != t;
}

/// Glass bottom sheet helper.
Future<T?> showGlassSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Glass(
        blur: 30,
        frosted: true,
        opacity: 0.1,
        tint: const Color(0xFFC4B5FD),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void toast(
  BuildContext context,
  String msg, {
  IconData icon = Iconsax.tick_circle,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1800),
        content: Row(
          children: [
            Icon(icon, color: AppColors.violetLight, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
      ),
    );
}

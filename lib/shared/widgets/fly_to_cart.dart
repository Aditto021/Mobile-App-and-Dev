/// MODULE: Fly-to-cart animation — Flies a product thumbnail into the cart
/// icon when something is added to the cart.
///
/// Contains: FlyToCart, FlyToCartState, _Flight, CartTarget,
/// _CartTargetState.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'product_widgets.dart';

/// Brief thumbnail feedback from a product to the cart.
class FlyToCart extends StatefulWidget {
  final Widget child;
  const FlyToCart({super.key, required this.child});

  static FlyToCartState? of(BuildContext context) =>
      context.findAncestorStateOfType<FlyToCartState>();

  @override
  State<FlyToCart> createState() => FlyToCartState();
}

class FlyToCartState extends State<FlyToCart> with TickerProviderStateMixin {
  /// Cart icons currently mounted; the most recent (top-most screen) wins.
  final List<_CartTargetState> _targets = [];

  final List<_Flight> _flights = [];

  void fly(GlobalKey source, String imageUrl) {
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return;
    }
    final srcBox = source.currentContext?.findRenderObject() as RenderBox?;
    final target = _targets.isEmpty ? null : _targets.last;
    final dstBox = target?.context.findRenderObject() as RenderBox?;
    final me = context.findRenderObject() as RenderBox?;
    if (srcBox == null || me == null || !srcBox.attached) return;
    final start = me.globalToLocal(
      srcBox.localToGlobal(srcBox.size.center(Offset.zero)),
    );
    final startSize = math.min(srcBox.size.width, 72.0);
    final end = dstBox != null && dstBox.attached
        ? me.globalToLocal(
            dstBox.localToGlobal(dstBox.size.center(Offset.zero)),
          )
        : Offset(me.size.width * 0.5, me.size.height - 40);

    final c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    final f = _Flight(c, start, end, startSize, imageUrl);
    setState(() => _flights.add(f));
    c.forward().whenComplete(() {
      if (target != null && target.mounted) target.pulse();
      if (mounted) setState(() => _flights.remove(f));
      c.dispose();
    });
  }

  @override
  void dispose() {
    for (final f in _flights) {
      f.c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        for (final f in _flights)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: f.c,
              builder: (_, _) {
                final t = Curves.easeInOutCubic.transform(f.c.value);
                // Control point lifted above the straight line for a nice arc.
                final ctrl = Offset(
                  (f.start.dx + f.end.dx) / 2,
                  math.min(f.start.dy, f.end.dy) - 70,
                );
                Offset at(double t) =>
                    f.start * ((1 - t) * (1 - t)) +
                    ctrl * (2 * (1 - t) * t) +
                    f.end * (t * t);
                final pos = at(t);
                final size = f.size * (1 - t * 0.82);
                return Stack(
                  children: [
                    Positioned(
                      left: pos.dx - size / 2,
                      top: pos.dy - size / 2,
                      child: Transform.rotate(
                        angle: 0,
                        child: Opacity(
                          opacity: t > 0.9 ? (1 - t) * 10 : 1,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.void2,
                              border: Border.all(
                                color: AppColors.violetLight,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ProductImage(f.url, padding: size * 0.1),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Flight {
  final AnimationController c;
  final Offset start, end;
  final double size;
  final String url;
  _Flight(this.c, this.start, this.end, this.size, this.url);
}

/// Registers the cart destination and plays a subtle confirmation pulse.
class CartTarget extends StatefulWidget {
  final Widget child;
  const CartTarget({super.key, required this.child});

  @override
  State<CartTarget> createState() => _CartTargetState();
}

class _CartTargetState extends State<CartTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  FlyToCartState? _host;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final h = FlyToCart.of(context);
    if (h != _host) {
      _host?._targets.remove(this);
      _host = h;
      _host?._targets.add(this);
    }
  }

  void pulse() {
    if (!MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _host?._targets.remove(this);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final v = _c.value;
        final scale = 1 + 0.12 * math.sin(v * math.pi) * (1 - v);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [Transform.scale(scale: scale, child: child)],
        );
      },
      child: widget.child,
    );
  }
}

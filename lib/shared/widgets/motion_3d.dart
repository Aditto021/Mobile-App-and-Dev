/// MODULE: 3D motion — the shared depth effects used across the app: cards
/// that tilt toward the pointer with a moving glare, perspective helpers for
/// 3D carousels, and a slow spin for decorative rings. Every effect switches
/// off when the phone asks for reduced motion.
///
/// Contains: Perspective, Tilt3D, _Tilt3DState, Spin, _SpinLoop,
/// _SpinLoopState.
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Builds 3D transforms with a shared, natural-looking camera depth.
class Perspective {
  Perspective._();

  /// Strength of the perspective (how close the "camera" is).
  static const depth = 0.0012;

  static Matrix4 camera() => Matrix4.identity()..setEntry(3, 2, depth);

  /// True when the user has asked the phone for less motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  /// Transform for one page of a 3D carousel. [delta] is how far the page is
  /// from the centre (0 = centred, ±1 = one page to the side).
  static Matrix4 carousel(double delta, {double turn = 0.55}) {
    final d = delta.clamp(-1.0, 1.0);
    if (d.abs() < 0.001) return Matrix4.identity();
    return camera()
      ..rotateY(-d * turn)
      ..scaleByDouble(1 - d.abs() * 0.12, 1 - d.abs() * 0.12, 1, 1);
  }
}

/// Tilts its child in 3D toward the mouse (on hover) or finger (on press),
/// with a soft glare that follows the pointer. Never blocks taps or scrolls.
class Tilt3D extends StatefulWidget {
  final Widget child;

  /// Largest tilt in radians (0.12 ≈ 7°).
  final double maxAngle;

  /// Corner radius used to clip the glare to the card's shape.
  final double radius;
  final bool glare;

  const Tilt3D({
    super.key,
    required this.child,
    this.maxAngle = 0.12,
    this.radius = 22,
    this.glare = true,
  });

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  /// Pointer position over the card, from (-1, -1) top-left to (1, 1).
  Offset _target = Offset.zero;

  void _aim(Offset local) {
    final box = context.size;
    if (box == null || box.isEmpty) return;
    setState(() {
      _target = Offset(
        (local.dx / box.width * 2 - 1).clamp(-1.0, 1.0),
        (local.dy / box.height * 2 - 1).clamp(-1.0, 1.0),
      );
    });
  }

  void _rest() {
    if (_target != Offset.zero) setState(() => _target = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    if (Perspective.reduced(context)) return widget.child;
    return MouseRegion(
      onHover: (e) => _aim(e.localPosition),
      onExit: (_) => _rest(),
      child: Listener(
        // Touch tilts toward where the finger lands; moves are ignored so a
        // scroll that starts on a card doesn't make it wobble.
        onPointerDown: (e) {
          if (e.kind == PointerDeviceKind.touch) _aim(e.localPosition);
        },
        onPointerUp: (e) {
          if (e.kind == PointerDeviceKind.touch) _rest();
        },
        onPointerCancel: (_) => _rest(),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: _target),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: widget.child,
          builder: (context, t, child) {
            final strength = math.min(1.0, t.distance);
            return Transform(
              alignment: Alignment.center,
              // At rest, no perspective: it would otherwise stack with any
              // 3D effect inside the card (such as the checkout card flip).
              transform: strength < 0.001
                  ? Matrix4.identity()
                  : (Perspective.camera()
                      ..rotateX(-t.dy * widget.maxAngle)
                      ..rotateY(t.dx * widget.maxAngle)),
              // Same structure at rest and while tilting, so hovering never
              // rebuilds the card underneath; only the glare's strength
              // changes.
              child: Stack(
                // Passthrough keeps the card's own size constraints.
                fit: StackFit.passthrough,
                children: [
                  child!,
                  if (widget.glare)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.radius),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(t.dx, t.dy),
                                radius: 1.1,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: 0.22 * strength,
                                  ),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Slowly and endlessly rotates its child (for decorative rings).
class Spin extends StatelessWidget {
  final Widget child;
  final Duration period;
  const Spin({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 8),
  });

  @override
  Widget build(BuildContext context) {
    if (Perspective.reduced(context)) return child;
    return _SpinLoop(period: period, child: child);
  }
}

class _SpinLoop extends StatefulWidget {
  final Widget child;
  final Duration period;
  const _SpinLoop({required this.child, required this.period});

  @override
  State<_SpinLoop> createState() => _SpinLoopState();
}

class _SpinLoopState extends State<_SpinLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _c, child: widget.child);
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../config/brand.dart';
import '../data/shop.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// A clipped coupon that tears at its perforation when applied to the cart.
class VoucherCard extends StatefulWidget {
  const VoucherCard({super.key});

  @override
  State<VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends State<VoucherCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  );
  bool _used = false;

  Future<void> _useCoupon() async {
    if (_used || context.read<Shop>().couponCode == Brand.couponCode) return;
    if (!context.read<Shop>().applyCoupon(Brand.couponCode)) return;

    setState(() => _used = true);
    HapticFeedback.mediumImpact();
    await Clipboard.setData(const ClipboardData(text: Brand.couponCode));

    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduceMotion) {
      _tear.value = 1;
    } else {
      try {
        await _tear.forward().orCancel;
      } on TickerCanceled {
        return;
      }
    }

    if (mounted) toast(context, 'Coupon applied to your cart and code copied');
  }

  @override
  void dispose() {
    _tear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alreadyApplied = context.select<Shop, bool>(
      (shop) => shop.couponCode == Brand.couponCode,
    );
    final used = _used || alreadyApplied;
    final appliedBeforeThisCard = alreadyApplied && !_used;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
      child: Semantics(
        button: !used,
        label: used ? 'Coupon applied to your cart' : 'Apply coupon',
        child: GestureDetector(
          onTap: used ? null : _useCoupon,
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: _tear,
                builder: (context, _) {
                  final t = Curves.easeInOutCubic.transform(
                    appliedBeforeThisCard ? 1 : _tear.value,
                  );
                  const stubWidth = 50.0;
                  return ClipPath(
                    clipper: const _TicketShape(),
                    child: Container(
                      height: 92,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF632B65),
                            Color(0xFF39305E),
                            Color(0xFF1B5261),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.magenta.withValues(alpha: 0.16),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(-18 * t, 0),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 22,
                                      right: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: AppColors.brandGradient,
                                          ),
                                          child: Icon(
                                            used
                                                ? Iconsax.tick_circle
                                                : Iconsax.ticket_discount,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 240,
                                            ),
                                            child: Column(
                                              key: ValueKey(used),
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  used
                                                      ? 'Coupon applied!'
                                                      : '${Brand.couponPercent}% off your first order',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Txt.h3.copyWith(
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  used
                                                      ? 'Discount is ready in your cart'
                                                      : 'Up to ${taka(Brand.couponMaxDiscount)} · tap to apply',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Txt.small.copyWith(
                                                    color: AppColors.textDim,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: stubWidth,
                                child: Transform.translate(
                                  offset: Offset(42 * t, -5 * t),
                                  child: Transform.rotate(
                                    angle: 0.12 * t,
                                    child: Center(
                                      child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text(
                                          used ? 'USED' : Brand.couponCode,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                            fontSize: used ? 10 : 12,
                                            color: used
                                                ? AppColors.champagne
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: constraints.maxWidth - stubWidth,
                            top: 16,
                            bottom: 16,
                            child: Opacity(
                              opacity: 1 - t,
                              child: const CustomPaint(
                                size: const Size(1, 60),
                                painter: _PerforationPainter(),
                              ),
                            ),
                          ),
                          if (used && t > 0.1)
                            Positioned(
                              left: constraints.maxWidth - stubWidth - 5,
                              top: 27,
                              child: Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: AppColors.champagne.withValues(
                                  alpha: math.sin(t * math.pi),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketShape extends CustomClipper<Path> {
  const _TicketShape();

  @override
  Path getClip(Size size) {
    const radius = 12.0;
    final notch = size.width - 50;
    final outer = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)),
      );
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(notch, 0), radius: radius))
      ..addOval(
        Rect.fromCircle(center: Offset(notch, size.height), radius: radius),
      );
    return Path.combine(PathOperation.difference, outer, holes);
  }

  @override
  bool shouldReclip(covariant _TicketShape oldClipper) => false;
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 1.2;
    for (double y = 0; y < size.height; y += 7) {
      canvas.drawLine(Offset.zero.translate(0, y), Offset(0, y + 3.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter oldDelegate) => false;
}

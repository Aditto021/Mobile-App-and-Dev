/// MODULE: 3D card preview — a live bank card shown above the card form. It
/// fills in as the user types, tilts toward the pointer, and flips over in 3D
/// to show the back when the CVV field is focused.
///
/// Contains: CardPreview3D, _CardFront, _CardBack, _Chip, _ChipLines.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/motion_3d.dart';

class CardPreview3D extends StatelessWidget {
  final TextEditingController number, expiry, cvv;
  final String holder;

  /// When true the card turns over to show its back (CVV side).
  final bool showBack;

  const CardPreview3D({
    super.key,
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.holder,
    required this.showBack,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = Perspective.reduced(context);
    return AspectRatio(
      aspectRatio: 1.586, // real bank-card proportions
      child: Tilt3D(
        radius: 20,
        child: ListenableBuilder(
          listenable: Listenable.merge([number, expiry, cvv]),
          builder: (context, _) => TweenAnimationBuilder<double>(
            tween: Tween(end: showBack ? math.pi : 0),
            duration: Duration(milliseconds: reduce ? 0 : 650),
            curve: Curves.easeInOutCubic,
            builder: (context, angle, _) {
              final back = angle > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                // A more distant camera than usual, so the near edge of
                // this wide card doesn't swing out over the form mid-flip.
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0006)
                  ..rotateY(angle),
                child: back
                    // The back face is pre-turned so it doesn't read mirrored.
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: _CardBack(cvv: cvv.text),
                      )
                    : _CardFront(
                        number: number.text,
                        expiry: expiry.text,
                        holder: holder,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardSurface(List<Color> colors) => BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
  ),
  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
  boxShadow: [
    BoxShadow(
      color: AppColors.violet.withValues(alpha: 0.35),
      blurRadius: 30,
      offset: const Offset(0, 14),
    ),
  ],
);

class _CardFront extends StatelessWidget {
  final String number, expiry, holder;
  const _CardFront({
    required this.number,
    required this.expiry,
    required this.holder,
  });

  String get _network => switch (number.isEmpty ? '' : number[0]) {
    '4' => 'VISA',
    '5' => 'Mastercard',
    '3' => 'AMEX',
    _ => 'CARD',
  };

  @override
  Widget build(BuildContext context) {
    final digits = number.replaceAll(' ', '');
    final shown = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) shown.write('  ');
      shown.write(i < digits.length ? digits[i] : '•');
    }
    const label = TextStyle(
      fontSize: 9,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w600,
      color: Colors.white60,
    );
    return Container(
      decoration: _cardSurface(const [
        Color(0xFF4F3B9A),
        Color(0xFF7955C7),
        Color(0xFFB16FAD),
      ]),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Chip(),
              const SizedBox(width: 10),
              const Icon(Iconsax.wifi, size: 18, color: Colors.white70),
              const Spacer(),
              Text(
                _network,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              shown.toString(),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('CARD HOLDER', style: label),
                    Text(
                      holder.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('EXPIRES', style: label),
                  Text(
                    expiry.isEmpty ? 'MM/YY' : expiry,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final String cvv;
  const _CardBack({required this.cvv});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardSurface(const [
        Color(0xFF3A2C73),
        Color(0xFF5B3F9E),
        Color(0xFF8A5BA6),
      ]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(height: 40, color: const Color(0xFF16121F)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 34,
                  width: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  child: Text(
                    // Masked like the CVV field itself.
                    cvv.isEmpty ? 'CVV' : '•' * cvv.length,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Color(0xFF292337),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// The gold EMV chip.
class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3C98B), Color(0xFFD9A55B), Color(0xFFF7DDB0)],
        ),
      ),
      child: CustomPaint(painter: _ChipLines()),
    );
  }
}

class _ChipLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66704A1A)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChipLines old) => false;
}

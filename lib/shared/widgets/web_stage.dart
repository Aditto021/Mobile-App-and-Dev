/// MODULE: Web stage — how the app sits in a wide browser window. On phones
/// it does nothing; on tablets and desktops the app is shown in a
/// phone-sized frame (so layouts never stretch), and on wide screens a brand
/// showcase panel appears beside it.
///
/// Contains: WebStage, _PhoneFrame, _Showcase, _Highlight.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/config/brand_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/state/shop_state.dart';
import 'brand_logo.dart';
import 'motion_3d.dart';

class WebStage extends StatelessWidget {
  final Widget child;
  const WebStage({super.key, required this.child});

  /// Below this width the app fills the window, as on a phone.
  static const frameFrom = 600.0;

  /// From this width the showcase panel appears beside the frame.
  static const showcaseFrom = 1100.0;

  static const _phone = Size(412, 892);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    // Phones, and windows too short for a frame, use the whole window.
    if (size.width < frameFrom || size.height < frameFrom) return child;

    final screen = Size(
      _phone.width,
      math.min(_phone.height, size.height - 48),
    );
    final phone = _PhoneFrame(
      child: MediaQuery(
        // The app lays itself out for the framed screen, not the window.
        data: mq.copyWith(
          size: screen,
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: SizedBox.fromSize(size: screen, child: child),
      ),
    );
    // On page load the phone swings in once, turning to face the viewer.
    final framed = Perspective.reduced(context)
        ? phone
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            child: phone,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform(
                alignment: Alignment.center,
                // Identity once settled, so it adds no perspective to the
                // 3D effects inside the app.
                transform: v == 1
                    ? Matrix4.identity()
                    : (Perspective.camera()
                        ..rotateY((1 - v) * -0.5)
                        ..rotateX((1 - v) * 0.12)),
                child: child,
              ),
            ),
          );

    if (size.width < showcaseFrom) return Center(child: framed);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Row(
            children: [
              const Expanded(child: _Showcase()),
              const SizedBox(width: 64),
              framed,
            ],
          ),
        ),
      ),
    );
  }
}

/// A slim device bezel with a soft violet glow around the app screen.
class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(54),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF342D4F), Color(0xFF15131F), Color(0xFF2A2440)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.30),
            blurRadius: 90,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(45),
        child: ColoredBox(
          // A touch darker than the page so the screen reads as glass.
          color: AppColors.void0.withValues(alpha: 0.45),
          child: child,
        ),
      ),
    );
  }
}

/// Brand story shown beside the app on wide screens.
class _Showcase extends StatelessWidget {
  const _Showcase();

  @override
  Widget build(BuildContext context) {
    final productCount = context.select<Shop, int>((s) => s.products.length);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final items = <Widget>[
      const Row(
        children: [
          BrandMark(size: 52),
          SizedBox(width: 14),
          BrandWordmark(size: 34),
        ],
      ),
      const SizedBox(height: 36),
      Text(
        Brand.tagline,
        style: Txt.h1.copyWith(fontSize: 46, height: 1.1, letterSpacing: -1.4),
      ),
      const SizedBox(height: 14),
      Text(
        Brand.banglaTagline,
        style: Txt.bangla.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.champagne,
        ),
      ),
      const SizedBox(height: 40),
      _Highlight(
        icon: Iconsax.shop,
        title: productCount > 0
            ? '$productCount products, ${categories.length} categories'
            : '${categories.length} categories',
        text: 'Phones, fashion, beauty, home and more.',
      ),
      const _Highlight(
        icon: Iconsax.wallet_3,
        title: 'bKash, Nagad, card or cash',
        text: 'Pay the way you already do.',
      ),
      _Highlight(
        icon: Iconsax.truck_fast,
        title: 'Free delivery over ${taka(Brand.freeDeliveryOver)}',
        text: 'Track every order live, step by step.',
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.champagne.withValues(alpha: 0.08),
          border: Border.all(
            color: AppColors.champagne.withValues(alpha: 0.35),
          ),
        ),
        child: Text.rich(
          TextSpan(
            style: Txt.body.copyWith(color: AppColors.textDim),
            children: [
              const TextSpan(text: 'Use '),
              TextSpan(
                text: Brand.couponCode,
                style: const TextStyle(
                  color: AppColors.champagne,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: ' for ${Brand.couponPercent}% off your first order',
              ),
            ],
          ),
        ),
      ),
    ];
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
    // Sits above the Navigator, so it needs its own Material for text styles.
    return Material(
      type: MaterialType.transparency,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 520,
          child: reduceMotion
              ? column
              : column
                    .animate()
                    .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
                    .slideX(begin: -0.04, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Highlight({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppColors.violet.withValues(alpha: 0.18),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, size: 22, color: AppColors.lavender),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Txt.h3),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: Txt.small.copyWith(color: AppColors.textFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

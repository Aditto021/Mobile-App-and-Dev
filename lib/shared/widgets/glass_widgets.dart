/// MODULE: Glass widgets — The frosted-glass building blocks used on every
/// screen: panels, buttons, badges, gradient text and section headers.
///
/// Contains: Glass, GlassTile, GradientBoxBorder, Pressable, _PressableState,
/// GlassIconButton, CountBadge, GlowButton, GradientText, SectionHeader.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Glass panel.
///
/// By default it is "baked" glass: a translucent gradient + specular rim
/// with no backdrop blur. Over the static nebula this looks the same as
/// real frosted glass but costs nothing per frame, which is what keeps the
/// app at 120 Hz. Pass [frosted] for a real blur (only for short-lived
/// surfaces like bottom sheets), and [backing] (0..1) for panels that float
/// over scrolling content so the content behind stays readable.
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final Color? tint;
  final BorderRadius? borderRadius;
  final bool border;
  final bool frosted;
  final double backing;

  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.blur = 18,
    this.opacity = 0.08,
    this.tint,
    this.borderRadius,
    this.border = true,
    this.frosted = false,
    this.backing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(radius);
    Widget panel = DecoratedBox(
      decoration: glassDecoration(
        br,
        opacity: opacity,
        tint: tint,
        border: border,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
    if (backing > 0) {
      panel = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          color: AppColors.void1.withValues(alpha: backing),
        ),
        child: panel,
      );
    }
    if (!frosted) return ClipRRect(borderRadius: br, child: panel);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: panel,
      ),
    );
  }
}

/// The glass look without a blur pass — for long lists (product grids)
/// where dozens of live blurs would cost frames. Over the dark nebula it
/// reads identically.
class GlassTile extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final Color? tint;
  final Gradient? gradient;
  const GlassTile({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding,
    this.opacity = 0.07,
    this.tint,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: gradient == null
          ? glassDecoration(br, opacity: opacity, tint: tint)
          : BoxDecoration(
              borderRadius: br,
              gradient: gradient,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
      child: ClipRRect(
        borderRadius: br,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

BoxDecoration glassDecoration(
  BorderRadius br, {
  double opacity = 0.08,
  Color? tint,
  bool border = true,
}) {
  final base = tint ?? Colors.white;
  return BoxDecoration(
    borderRadius: br,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          base.withValues(alpha: opacity * 0.65),
          AppColors.void1,
        ),
        Color.alphaBlend(
          base.withValues(alpha: opacity * 0.3),
          AppColors.void1,
        ),
      ],
    ),
    border: border
        ? GradientBoxBorder(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                AppColors.violetLight.withValues(alpha: 0.08),
                AppColors.champagne.withValues(alpha: 0.10),
              ],
            ),
          )
        : null,
  );
}

/// A 1px border painted with a gradient — the specular rim that makes
/// glass look like glass.
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  const GradientBoxBorder({required this.gradient, this.width = 1});

  @override
  BorderSide get bottom => BorderSide.none;
  @override
  BorderSide get top => BorderSide.none;
  @override
  bool get isUniform => true;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (shape == BoxShape.circle) {
      canvas.drawCircle(rect.center, rect.shortestSide / 2 - width / 2, paint);
    } else if (borderRadius != null) {
      canvas.drawRRect(borderRadius.toRRect(rect).deflate(width / 2), paint);
    } else {
      canvas.drawRect(rect.deflate(width / 2), paint);
    }
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);
}

/// Brief, restrained press feedback with a light haptic tick.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.haptic = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final enabled = widget.onTap != null;
    // With a mouse (web/desktop): hand cursor and a gentle lift on hover.
    final scale = reduceMotion
        ? 1.0
        : _down
        ? widget.scale.clamp(0.96, 1.0)
        : _hover && enabled
        ? 1.02
        : 1.0;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: enabled ? (_) => setState(() => _hover = true) : null,
      onExit: enabled ? (_) => setState(() => _hover = false) : null,
      child: _gestures(scale, reduceMotion),
    );
  }

  Widget _gestures(double scale, bool reduceMotion) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: scale,
        duration: Duration(
          milliseconds: reduceMotion ? 0 : (_down ? 100 : 220),
        ),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Round glass icon button with optional badge.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final int badge;
  final double size;
  final Color? color;
  final Key? iconKey;
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = 0,
    this.size = 46,
    this.color,
    this.iconKey,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Glass(
              radius: size / 2,
              opacity: 0.09,
              child: Center(
                child: Icon(
                  icon,
                  key: iconKey,
                  size: size * 0.46,
                  color: color ?? AppColors.text,
                ),
              ),
            ),
            if (badge > 0)
              Positioned(right: -2, top: -2, child: CountBadge(count: badge)),
          ],
        ),
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  final int count;
  const CountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.void1, width: 1.6),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Primary call-to-action: violet→magenta gradient pill with a soft neon
/// glow and a light sweep that passes over it periodically.
class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final bool expanded;
  final Gradient gradient;
  final bool shine;
  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 56,
    this.expanded = true,
    this.gradient = AppColors.brandGradient,
    this.shine = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    // The pill itself (gradient + label). The sweep is applied to this
    // only, so it never paints over the glow outside the rounded shape.
    Widget pill = Container(
      height: height,
      width: expanded ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (shine &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context)) {
      pill = ClipRRect(
        borderRadius: radius,
        child: pill
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              delay: 2200.ms,
              duration: 1400.ms,
              color: Colors.white.withValues(alpha: 0.45),
              angle: 0.5,
            ),
      );
    }
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: pill,
    );
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: RepaintBoundary(
        child: Pressable(onTap: onTap, child: content),
      ),
    );
  }
}

/// Text filled with a gradient.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = AppColors.textGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) =>
          gradient.createShader(Rect.fromLTWH(0, 0, r.width, r.height)),
      child: Text(text, style: style),
    );
  }
}

/// Section header with optional "see all" action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback? onAction;
  final Widget? trailing;
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action = 'See all',
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: AppColors.auroraGradient,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.magenta.withValues(alpha: 0.38),
                            blurRadius: 9,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        title,
                        style: Txt.h2.copyWith(letterSpacing: -0.45),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: Txt.small.copyWith(color: AppColors.textDim),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
          if (onAction != null)
            Pressable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Row(
                  children: [
                    Text(
                      action,
                      style: Txt.small.copyWith(
                        color: AppColors.champagne,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.champagne,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

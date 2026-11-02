import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/shop.dart';
import '../theme/app_theme.dart';
import 'fly_to_cart.dart';
import 'glass.dart';

/// A neutral photo well that keeps product colours and outlines clear.
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double padding;
  const ProductImage(
    this.url, {
    super.key,
    this.fit = BoxFit.contain,
    this.padding = 10,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF7F4F0)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: LayoutBuilder(
          builder: (context, box) {
            // Decode at displayed size (rounded up to 128px buckets so sizes
            // share cache entries) instead of full resolution: far less
            // memory and no decode hitches while scrolling.
            final dpr = MediaQuery.devicePixelRatioOf(context);
            final w = box.maxWidth.isFinite ? box.maxWidth : 300.0;
            final px = ((w * dpr / 128).ceil() * 128).clamp(128, 1280);
            return RepaintBoundary(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: fit,
                memCacheWidth: px,
                fadeInDuration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                placeholder: (_, _) => const ShimmerBox(),
                errorWidget: (_, _, _) => Center(
                  child: Icon(
                    Iconsax.box_remove,
                    color: const Color(0xFF60677A),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double radius;
  const ShimmerBox({super.key, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0xFFE0E2E9),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return placeholder;
    }
    return placeholder
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1600.ms,
          color: Colors.white.withValues(alpha: 0.45),
        );
  }
}

class PriceTag extends StatelessWidget {
  final Product p;
  final double size;
  final bool lightSurface;
  const PriceTag(
    this.p, {
    super.key,
    this.size = 16,
    this.lightSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 6,
      children: [
        Text(
          taka(p.price),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.1,
            color: lightSurface
                ? (p.discount > 0
                      ? const Color(0xFFB72D70)
                      : const Color(0xFF251D35))
                : (p.discount > 0 ? AppColors.cyan : AppColors.text),
          ),
        ),
        if (p.discount > 0)
          Text(
            taka(p.originalPrice),
            style: TextStyle(
              fontSize: size * 0.68,
              color: AppColors.textFaint,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textFaint,
            ),
          ),
      ],
    );
  }
}

class RatingRow extends StatelessWidget {
  final double rating;
  final int? sold;
  final bool lightSurface;
  const RatingRow(
    this.rating, {
    super.key,
    this.sold,
    this.lightSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 15, color: AppColors.gold),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: Txt.small.copyWith(
            fontWeight: FontWeight.w700,
            color: lightSurface ? const Color(0xFF4F465D) : null,
          ),
        ),
        if (sold != null) ...[
          Text('  ·  ', style: Txt.small.copyWith(color: AppColors.textFaint)),
          Flexible(
            child: Text(
              '${sold! >= 1000 ? '${(sold! / 1000).toStringAsFixed(1)}k' : sold} sold',
              overflow: TextOverflow.ellipsis,
              style: Txt.small.copyWith(
                color: lightSurface
                    ? const Color(0xFF8E8798)
                    : AppColors.textDim,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class DiscountChip extends StatelessWidget {
  final int discount;
  const DiscountChip(this.discount, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF5277), Color(0xFFE13C88), Color(0xFFAA42D8)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '-$discount%',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// A clear wishlist control with a stable touch target.
class HeartButton extends StatelessWidget {
  final Product product;
  final double size;
  final bool glass;
  const HeartButton(
    this.product, {
    super.key,
    this.size = 40,
    this.glass = true,
  });

  @override
  Widget build(BuildContext context) {
    final wished = context.select<Shop, bool>((s) => s.isWished(product.id));
    final label = wished ? 'Remove from wishlist' : 'Add to wishlist';
    return Semantics(
      button: true,
      label: label,
      toggled: wished,
      child: Tooltip(
        message: label,
        child: Pressable(
          onTap: () => context.read<Shop>().toggleWish(product),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: glass ? Colors.white : AppColors.void2,
              shape: BoxShape.circle,
              border: Border.all(
                color: glass ? const Color(0xFFD5D8E2) : AppColors.glassBorder,
              ),
            ),
            child: Icon(
              wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 21,
              color: wished
                  ? const Color(0xFFB52E54)
                  : (glass ? const Color(0xFF353C50) : AppColors.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Product-led card: neutral photo well, solid surface and clear price.
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final String heroPrefix;
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.heroPrefix = 'grid',
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Pressable(
      onTap: widget.onTap,
      scale: 0.985,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xBFE9DDF4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.magenta.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: '${widget.heroPrefix}-${p.id}',
                      child: KeyedSubtree(
                        key: _imageKey,
                        child: ProductImage(p.thumbnail, padding: 16),
                      ),
                    ),
                  ),
                  if (p.discount > 0)
                    Positioned(
                      left: 9,
                      top: 9,
                      child: DiscountChip(p.discount),
                    ),
                  Positioned(right: 7, top: 7, child: HeartButton(p, size: 40)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: Color(0xFF292337),
                    ),
                  ),
                  const SizedBox(height: 7),
                  RatingRow(p.rating, sold: p.sold, lightSurface: true),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: PriceTag(p, size: 16, lightSurface: true),
                      ),
                      const SizedBox(width: 4),
                      AddButton(product: p, sourceKey: _imageKey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddButton extends StatelessWidget {
  final Product product;
  final GlobalKey sourceKey;
  const AddButton({super.key, required this.product, required this.sourceKey});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add ' + product.title + ' to cart',
      child: Tooltip(
        message: 'Add to cart',
        child: Pressable(
          scale: 0.8,
          onTap: () {
            HapticFeedback.mediumImpact();
            FlyToCart.of(context)?.fly(sourceKey, product.thumbnail);
            context.read<Shop>().addToCart(product);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Staggered entrance used for grid/list items.
extension Entrance on Widget {
  Widget entrance(int index, {int baseMs = 0}) => Builder(
    builder: (context) {
      if (MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context))
        return this;
      return animate(delay: (20 * (index % 4)).ms)
          .fadeIn(duration: 220.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.025,
            end: 0,
            duration: 260.ms,
            curve: Curves.easeOutCubic,
          );
    },
  );
}

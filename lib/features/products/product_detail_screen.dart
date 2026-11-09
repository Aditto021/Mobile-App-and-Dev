/// MODULE: Product detail screen — Image gallery, price, colour picker,
/// delivery info, reviews, similar items and Add to cart / Buy now.
///
/// Contains: ProductDetailScreen, _ProductDetailScreenState, _Pill,
/// _DeliveryCard, _ReviewTile.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/config/brand_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/state/shop_state.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/fly_to_cart.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/product_widgets.dart';
import '../cart/cart_screen.dart';
import '../checkout/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String heroTag;
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.heroTag,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pc = PageController();
  final _scroll = ScrollController();
  final _imageKey = GlobalKey();
  int _qty = 1;
  int _variant = 0;
  bool _expanded = false;

  static const _swatches = [
    Color(0xFFA78BFA),
    Color(0xFF1E1B4B),
    Color(0xFFF5F3FF),
    Color(0xFFF472B6),
    Color(0xFF22D3EE),
  ];

  @override
  void dispose() {
    _pc.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _add() {
    HapticFeedback.mediumImpact();
    FlyToCart.of(context)?.fly(_imageKey, widget.product.thumbnail);
    context.read<Shop>().addToCart(widget.product, _qty);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final shop = context.watch<Shop>();
    final top = MediaQuery.paddingOf(context).top;
    final imageH = MediaQuery.sizeOf(context).width * 0.95;
    final similar = shop
        .inCategory(p.category)
        .where((e) => e.id != p.id)
        .toList();
    final cat = categoryOf(p.category);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Gallery with parallax + depth fade on scroll.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: imageH + top,
                  child: AnimatedBuilder(
                    animation: _scroll,
                    builder: (_, child) {
                      final offset = _scroll.hasClients ? _scroll.offset : 0.0;
                      return Transform.translate(
                        offset: Offset(0, offset * 0.45),
                        child: Opacity(
                          opacity: (1 - offset / imageH).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: offset < 0
                                ? 1 - offset / 600
                                : 1 - (offset / imageH) * 0.12,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(top: top + 50),
                      child: Stack(
                        children: [
                          // Spotlight
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  radius: 0.7,
                                  colors: [
                                    cat.color.withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          PageView.builder(
                            controller: _pc,
                            itemCount: p.images.length,
                            itemBuilder: (_, i) {
                              final img = ProductImage(
                                p.images[i],
                                padding: 30,
                              );
                              return i == 0
                                  ? Hero(
                                      tag: widget.heroTag,
                                      child: KeyedSubtree(
                                        key: _imageKey,
                                        child: img,
                                      ),
                                    )
                                  : img;
                            },
                          ),
                          if (p.images.length > 1)
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: SmoothPageIndicator(
                                  controller: _pc,
                                  count: p.images.length,
                                  effect: WormEffect(
                                    dotHeight: 7,
                                    dotWidth: 7,
                                    spacing: 7,
                                    activeDotColor: AppColors.violetLight,
                                    dotColor: Colors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child:
                    Glass(
                          blur: 24,
                          opacity: 0.08,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(34),
                          ),
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 150),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _Pill(
                                    icon: cat.icon,
                                    label: cat.name,
                                    color: cat.color,
                                  ),
                                  const SizedBox(width: 8),
                                  _Pill(
                                    icon: Iconsax.verify,
                                    label: p.brand,
                                    color: AppColors.mint,
                                  ),
                                  const Spacer(),
                                  if (p.discount > 0) DiscountChip(p.discount),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                p.title,
                                style: Txt.h1.copyWith(fontSize: 24),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (i) =>
                                        Icon(
                                          i < p.rating.round()
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 18,
                                          color: AppColors.gold,
                                        ).animate().scale(
                                          delay: (300 + i * 70).ms,
                                          curve: Curves.elasticOut,
                                          duration: 700.ms,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${p.rating.toStringAsFixed(1)}  ·  ${p.reviews.length} reviews  ·  ${p.sold} sold',
                                      style: Txt.small.copyWith(
                                        color: AppColors.textDim,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(child: PriceTag(p, size: 28)),
                                  QtyStepper(
                                    qty: _qty,
                                    onChanged: (v) =>
                                        setState(() => _qty = v.clamp(1, 20)),
                                    size: 36,
                                  ),
                                ],
                              ),
                              if (p.discount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'You save ${taka(p.originalPrice - p.price)}',
                                    style: Txt.small.copyWith(
                                      color: AppColors.mint,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 22),
                              Text('Colour', style: Txt.h3),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  for (var i = 0; i < _swatches.length; i++)
                                    Pressable(
                                      onTap: () => setState(() => _variant = i),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutBack,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        width: 38,
                                        height: 38,
                                        padding: EdgeInsets.all(
                                          i == _variant ? 4 : 0,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: i == _variant
                                                ? Colors.white
                                                : Colors.white24,
                                            width: i == _variant ? 2 : 1,
                                          ),
                                          boxShadow: i == _variant
                                              ? [
                                                  BoxShadow(
                                                    color: _swatches[i]
                                                        .withValues(alpha: 0.7),
                                                    blurRadius: 14,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _swatches[i],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              _DeliveryCard(stock: p.stock),
                              const SizedBox(height: 22),
                              Text('About this item', style: Txt.h3),
                              const SizedBox(height: 8),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: Text(
                                  p.description,
                                  maxLines: _expanded ? null : 3,
                                  overflow: _expanded
                                      ? null
                                      : TextOverflow.ellipsis,
                                  style: Txt.body.copyWith(
                                    color: AppColors.textDim,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _expanded = !_expanded),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _expanded ? 'Show less' : 'Read more',
                                    style: const TextStyle(
                                      color: AppColors.violetLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Text('Reviews', style: Txt.h3),
                                  const Spacer(),
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                  Text(
                                    ' ${p.rating.toStringAsFixed(1)} / 5',
                                    style: Txt.small,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              for (final (i, r) in p.reviews.indexed)
                                _ReviewTile(r).entrance(i),
                              if (similar.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                Text('You may also like', style: Txt.h3),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height:
                                      330 +
                                      ((MediaQuery.textScalerOf(context)
                                                      .scale(1) -
                                                  1) *
                                              150)
                                          .clamp(0, 180),
                                  child: ListView.separated(
                                    clipBehavior: Clip.none,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: similar.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, i) => SizedBox(
                                      width: 165,
                                      child: ProductCard(
                                        product: similar[i],
                                        heroPrefix: 'sim${p.id}',
                                        onTap: () => Navigator.of(context)
                                            .pushReplacement(
                                              MaterialPageRoute(
                                                builder: (_) => ProductDetailScreen(
                                                  product: similar[i],
                                                  heroTag:
                                                      'sim${p.id}-${similar[i].id}',
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        .animate()
                        .slideY(
                          begin: 0.25,
                          duration: 650.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(),
              ),
            ],
          ),
          // Floating top bar
          Positioned(
            top: top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GlassIconButton(
                  icon: Iconsax.arrow_left_2,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                HeartButton(p, size: 46),
                const SizedBox(width: 10),
                GlassIconButton(
                  icon: Iconsax.share,
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${p.title} — ${taka(p.price)} on ${Brand.appName}',
                      ),
                    );
                    toast(context, 'Link copied to share');
                  },
                ),
                const SizedBox(width: 10),
                CartTarget(
                  child: GlassIconButton(
                    icon: Iconsax.shopping_cart,
                    badge: shop.cartCount,
                    onTap: () =>
                        go(context, const CartScreen(standalone: true)),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          // Bottom action bar
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 14,
            child: Glass(
              radius: 30,
              blur: 26,
              backing: 0.82,
              opacity: 0.1,
              tint: const Color(0xFFC4B5FD),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: _add,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: AppColors.violetLight.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.shopping_cart, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Add to cart',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GlowButton(
                      label: 'Buy now',
                      height: 54,
                      onTap: () {
                        if (shop.qtyOf(p.id) == 0) shop.addToCart(p, _qty);
                        go(context, const CheckoutScreen());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ).animate().slideY(
            begin: 1.4,
            delay: 250.ms,
            duration: 700.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color.lerp(color, Colors.white, 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final int stock;
  const _DeliveryCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        Iconsax.truck_fast,
        'Delivery in 1–3 days',
        'Free over ${taka(Brand.freeDeliveryOver)} · Dhaka next-day',
      ),
      (
        Iconsax.money,
        'Cash on delivery available',
        'Also bKash, Nagad & cards',
      ),
      (
        Iconsax.shield_tick,
        '7-day easy returns',
        '100% authentic, quality checked',
      ),
      (
        Iconsax.box,
        stock > 20 ? 'In stock' : 'Only $stock left',
        'Ships from ${Brand.appName} warehouse',
      ),
    ];
    return GlassTile(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(r.$1, size: 19, color: AppColors.violetLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.$2,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: i == 3 && stock <= 20 ? AppColors.rose : null,
                        ),
                      ),
                      Text(
                        r.$3,
                        style: Txt.small.copyWith(
                          color: AppColors.textDim,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i < rows.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review r;
  const _ReviewTile(this.r);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassTile(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.violet.withValues(alpha: 0.35),
              child: Text(
                r.name[0],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      for (var i = 0; i < 5; i++)
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: i < r.rating ? AppColors.gold : Colors.white24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    r.comment,
                    style: Txt.small.copyWith(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w400,
                    ),
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

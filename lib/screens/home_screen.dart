import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../config/brand.dart';
import '../data/models.dart';
import '../data/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/product_widgets.dart';
import '../widgets/space_background.dart';
import '../widgets/voucher_card.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';
import 'shell.dart';

void openProduct(BuildContext context, Product p, String heroPrefix) => go(
  context,
  ProductDetailScreen(product: p, heroTag: '$heroPrefix-${p.id}'),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only rebuild when the catalogue becomes ready — cart/wishlist changes
    // are handled by the small widgets that show them.
    final shop = context.read<Shop>();
    if (!context.select<Shop, bool>((s) => s.ready)) {
      return const SizedBox.shrink();
    }
    final top = MediaQuery.paddingOf(context).top;
    final feed = shop.forYou;
    return ParallaxScroll(
      child: RefreshIndicator(
        color: AppColors.violetLight,
        backgroundColor: AppColors.void2,
        edgeOffset: top + 60,
        onRefresh: () => Future.delayed(const Duration(milliseconds: 900)),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: top + 10)),
            const SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(child: _SearchBar()),
            const SliverToBoxAdapter(child: _HeroCarousel()),
            const SliverToBoxAdapter(child: _CategoryStrip()),
            const SliverToBoxAdapter(child: _FlashSale()),
            const SliverToBoxAdapter(child: VoucherCard()),
            SliverToBoxAdapter(
              child: _HorizontalShelf(
                title: 'Top rated',
                subtitle: 'Explore the highest-rated picks',
                products: shop.topRated,
                heroPrefix: 'top',
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Just for you',
                subtitle: 'Picked from ${shop.products.length} products',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childCount: feed.length,
                itemBuilder: (context, i) => ProductCard(
                  product: feed[i],
                  heroPrefix: 'grid',
                  onTap: () => openProduct(context, feed[i], 'grid'),
                ).entrance(i),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = context.select<Shop, String?>((s) => s.userName) ?? 'Shopper';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 14),
      child: Row(
        children: [
          const BrandMark(size: 40, spin: false),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $name 👋',
                  style: Txt.small.copyWith(color: AppColors.textDim),
                ),
                const BrandWordmark(size: 22),
              ],
            ),
          ),
          GlassIconButton(
            icon: Iconsax.notification,
            badge: 3,
            onTap: () => go(context, const NotificationsScreen()),
          ),
        ],
      ),
    ).entrance(0);
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Hero(
        tag: 'search-bar',
        child: Material(
          type: MaterialType.transparency,
          child: Pressable(
            onTap: () => go(context, const SearchScreen()),
            child: Glass(
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 22,
                      color: AppColors.textDim,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search products, brands and more',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Txt.body.copyWith(color: AppColors.textDim),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: AppColors.textDim,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner {
  final String kicker, title, cta;
  final List<Color> colors;
  final String category;
  const _Banner(this.kicker, this.title, this.cta, this.colors, this.category);
}

const _banners = [
  _Banner(
    'EVERYDAY ESSENTIALS',
    'Find your next\nfavourite phone',
    'Shop phones',
    [Color(0xFF6D28D9), Color(0xFFDB2777)],
    'smartphones',
  ),
  _Banner('NEW SEASON', 'Find your\nsignature scent', 'Explore', [
    Color(0xFF4338CA),
    Color(0xFF9333EA),
  ], 'fragrances'),
  _Banner('WORK FROM ANYWHERE', 'Laptops for\nwork and play', 'View laptops', [
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
  ], 'laptops'),
  _Banner('TIME IS LUXURY', 'Make time for\ngreat style', 'Discover', [
    Color(0xFFA21CAF),
    Color(0xFF6D28D9),
  ], 'mens-watches'),
];

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _pc = PageController(viewportFraction: 0.92);
  Timer? _autoPlay;
  bool _autoPlayEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final autoPlayEnabled =
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        TickerMode.of(context);
    if (autoPlayEnabled == _autoPlayEnabled) return;
    _autoPlayEnabled = autoPlayEnabled;
    _autoPlay?.cancel();
    if (autoPlayEnabled) {
      _autoPlay = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!_pc.hasClients || !mounted) return;
        final current = _pc.page?.round() ?? 0;
        _pc.animateToPage(
          (current + 1) % _banners.length,
          duration: const Duration(milliseconds: 720),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.read<Shop>();
    return Column(
      children: [
        SizedBox(
          height: 176,
          child: PageView.builder(
            controller: _pc,
            itemCount: _banners.length,
            itemBuilder: (context, i) {
              final banner = _banners[i];
              final items = shop.inCategory(banner.category);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Pressable(
                  onTap: () =>
                      go(context, ProductListScreen.category(banner.category)),
                  child: GlassTile(
                    radius: 20,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: banner.colors,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner.kicker,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  banner.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.24,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        banner.cta,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (items.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 104,
                                height: 124,
                                child: ProductImage(items.first.thumbnail),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _pc,
          count: _banners.length,
          effect: ExpandingDotsEffect(
            dotHeight: 5,
            dotWidth: 5,
            expansionFactor: 3,
            activeDotColor: AppColors.violetLight,
            dotColor: AppColors.glassBorder,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: 'Categories',
          onAction: () => ShellScope.of(context)?.goTab(1),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = categories[i];
              return Pressable(
                onTap: () => go(context, ProductListScreen.category(c.id)),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.alphaBlend(
                                c.color.withValues(alpha: 0.54),
                                const Color(0xFF28223A),
                              ),
                              Color.alphaBlend(
                                c.color.withValues(alpha: 0.28),
                                const Color(0xFF191725),
                              ),
                            ],
                          ),
                          border: Border.all(
                            color: c.color.withValues(alpha: 0.52),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.color.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(c.icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ).entrance(i, baseMs: 250);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _FlashSale extends StatelessWidget {
  const _FlashSale();

  @override
  Widget build(BuildContext context) {
    final items = context.read<Shop>().flashSale;
    return Column(
      children: [
        SectionHeader(
          title: 'Discover deals',
          subtitle: 'Great products, lower prices',
          onAction: () => go(context, ProductListScreen.flash()),
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _FlashCard(items[i]).entrance(i, baseMs: 300),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FlashCard extends StatelessWidget {
  final Product p;
  const _FlashCard(this.p);

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => openProduct(context, p, 'flash'),
      child: SizedBox(
        width: 150,
        child: GlassTile(
          radius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: 'flash-${p.id}',
                        child: ProductImage(p.thumbnail),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: DiscountChip(p.discount),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 5),
                    PriceTag(p, size: 14.5),
                    const SizedBox(height: 9),
                    RatingRow(p.rating),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Voucher ticket with perforated edge and a copy-code action.
class _VoucherCard extends StatelessWidget {
  const _VoucherCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
      child: Pressable(
        scale: 0.98,
        onTap: () {
          Clipboard.setData(const ClipboardData(text: Brand.couponCode));
          HapticFeedback.mediumImpact();
          toast(
            context,
            'Code ${Brand.couponCode} copied — apply it in your cart',
            icon: Iconsax.ticket_discount,
          );
        },
        child: ClipPath(
          clipper: _TicketClipper(),
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF632B65),
                  const Color(0xFF39305E),
                  const Color(0xFF1B5261),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 22),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                  ),
                  child: const Icon(
                    Iconsax.ticket_discount,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Brand.couponPercent}% off your first order',
                        style: Txt.h3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Up to ${taka(Brand.couponMaxDiscount)} · tap to copy',
                        style: Txt.small.copyWith(color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                CustomPaint(size: const Size(1, 60), painter: _DashPainter()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      Brand.couponCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const r = 12.0;
    final notchX = s.width - 50;
    final p = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(22)),
      );
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(notchX, 0), radius: r))
      ..addOval(Rect.fromCircle(center: Offset(notchX, s.height), radius: r));
    return Path.combine(PathOperation.difference, p, holes);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    for (double y = 0; y < size.height; y += 7) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 3.5), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HorizontalShelf extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Product> products;
  final String heroPrefix;
  const _HorizontalShelf({
    required this.title,
    required this.subtitle,
    required this.products,
    required this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          onAction: () => go(context, ProductListScreen.topRated()),
        ),
        SizedBox(
          height: 328,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 172,
              child: ProductCard(
                product: products[i],
                heroPrefix: heroPrefix,
                onTap: () => openProduct(context, products[i], heroPrefix),
              ),
            ).entrance(i),
          ),
        ),
        const SizedBox(height: 26),
      ],
    );
  }
}

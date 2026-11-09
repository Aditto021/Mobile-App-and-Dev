/// MODULE: Product list screen — A full grid of products (a category, flash
/// sale or top rated) with sort chips.
///
/// Contains: ListSource, SortMode, ProductListScreen,
/// _ProductListScreenState, SortChips.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/state/shop_state.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/product_widgets.dart';
import '../../shared/widgets/space_background.dart';
import '../home/home_screen.dart';

enum ListSource { category, flash, topRated }

enum SortMode { popular, priceLow, priceHigh, rating, discount }

const sortLabels = {
  SortMode.popular: 'Popular',
  SortMode.priceLow: 'Price ↑',
  SortMode.priceHigh: 'Price ↓',
  SortMode.rating: 'Top rated',
  SortMode.discount: 'Biggest deals',
};

List<Product> sortProducts(List<Product> list, SortMode m) {
  final l = [...list];
  switch (m) {
    case SortMode.popular:
      l.sort((a, b) => b.sold.compareTo(a.sold));
    case SortMode.priceLow:
      l.sort((a, b) => a.price.compareTo(b.price));
    case SortMode.priceHigh:
      l.sort((a, b) => b.price.compareTo(a.price));
    case SortMode.rating:
      l.sort((a, b) => b.rating.compareTo(a.rating));
    case SortMode.discount:
      l.sort((a, b) => b.discount.compareTo(a.discount));
  }
  return l;
}

class ProductListScreen extends StatefulWidget {
  final ListSource source;
  final String? categoryId;
  const ProductListScreen._(this.source, [this.categoryId]);

  factory ProductListScreen.category(String id) =>
      ProductListScreen._(ListSource.category, id);
  factory ProductListScreen.flash() =>
      const ProductListScreen._(ListSource.flash);
  factory ProductListScreen.topRated() =>
      const ProductListScreen._(ListSource.topRated);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  SortMode _sort = SortMode.popular;

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<Shop>();
    final (title, base) = switch (widget.source) {
      ListSource.category => (
        categoryOf(widget.categoryId!).name,
        shop.inCategory(widget.categoryId!),
      ),
      ListSource.flash => ('⚡ Flash Sale', shop.flashSale),
      ListSource.topRated => ('Top rated', shop.topRated),
    };
    final items = sortProducts(base, _sort);
    return Scaffold(
      body: Column(
        children: [
          TopBar(title: title, subtitle: '${items.length} products'),
          SortChips(value: _sort, onChanged: (m) => setState(() => _sort = m)),
          Expanded(
            child: ParallaxScroll(
              child: MasonryGridView.count(
                key: ValueKey(_sort),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 40),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                itemCount: items.length,
                itemBuilder: (context, i) => ProductCard(
                  product: items[i],
                  heroPrefix: 'list',
                  onTap: () => openProduct(context, items[i], 'list'),
                ).entrance(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SortChips extends StatelessWidget {
  final SortMode value;
  final ValueChanged<SortMode> onChanged;
  const SortChips({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Iconsax.sort, size: 20, color: AppColors.textDim),
          ),
          for (final m in SortMode.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Pressable(
                onTap: () => onChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: m == value ? AppColors.brandGradient : null,
                    color: m == value
                        ? null
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: m == value
                          ? Colors.white30
                          : AppColors.glassBorder,
                    ),
                    boxShadow: m == value
                        ? [
                            BoxShadow(
                              color: AppColors.violet.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    sortLabels[m]!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: m == value ? Colors.white : AppColors.textDim,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

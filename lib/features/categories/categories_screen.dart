/// MODULE: Categories (Explore) screen — Category rail on the left, products
/// of the selected category on the right.
///
/// Contains: CategoriesScreen, _CategoriesScreenState, _CategoryBanner,
/// _MiniCard.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/state/shop_state.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/motion_3d.dart';
import '../../shared/widgets/product_widgets.dart';
import '../home/home_screen.dart';
import '../products/product_list_screen.dart';
import '../search/search_screen.dart';

/// Explore tab: category rail on the left, products of the selected
/// category on the right.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _sel = 0;

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<Shop>();
    final c = categories[_sel];
    final items = shop.inCategory(c.id);
    return Column(
      children: [
        TopBar(
          title: 'Explore',
          subtitle: '${categories.length} categories',
          back: false,
          actions: [
            GlassIconButton(
              icon: Icons.search_rounded,
              onTap: () => go(context, const SearchScreen()),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rail
              SizedBox(
                width: 92,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(10, 6, 0, 120),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final on = i == _sel;
                    return Pressable(
                      onTap: () => setState(() => _sel = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: on
                              ? LinearGradient(
                                  colors: [
                                    cat.color.withValues(alpha: 0.4),
                                    AppColors.violet.withValues(alpha: 0.2),
                                  ],
                                )
                              : null,
                          border: Border.all(
                            color: on ? Colors.white24 : Colors.transparent,
                          ),
                          boxShadow: on
                              ? [
                                  BoxShadow(
                                    color: cat.color.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: on ? 1.15 : 1,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                              child: Icon(
                                cat.icon,
                                size: 24,
                                color: on ? Colors.white : AppColors.textDim,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: on
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: on ? Colors.white : AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).entrance(i);
                  },
                ),
              ),
              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  ),
                  child: ListView(
                    key: ValueKey(_sel),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 6, 16, 120),
                    children: [
                      _CategoryBanner(cat: c, count: items.length),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, i) =>
                            _MiniCard(items[i]).entrance(i),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryBanner extends StatelessWidget {
  final CategoryInfo cat;
  final int count;
  const _CategoryBanner({required this.cat, required this.count});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: () => go(context, ProductListScreen.category(cat.id)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 130),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              cat.color.withValues(alpha: 0.55),
              AppColors.violet.withValues(alpha: 0.35),
            ],
          ),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cat.name, style: Txt.h2),
                  Text(
                    cat.bangla,
                    style: Txt.bangla.copyWith(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${plural(count, 'item')} · See all',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Txt.small.copyWith(color: Colors.white),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              cat.icon,
              size: 48,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Product p;
  const _MiniCard(this.p);

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => openProduct(context, p, 'cat'),
      child: Tilt3D(
        radius: 20,
        child: GlassTile(
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'cat-${p.id}',
                  child: ProductImage(p.thumbnail),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    PriceTag(p, size: 13.5),
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

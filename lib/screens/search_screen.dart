import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/product_widgets.dart';
import 'home_screen.dart';
import 'product_list_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _q = '';
  SortMode _sort = SortMode.popular;

  static const _trending = [
    'iPhone',
    'Perfume',
    'Watch',
    'Laptop',
    'Sunglasses',
    'Shoes',
    'Lipstick',
    'Sofa',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 220),
      () => setState(() => _q = v),
    );
  }

  void _submit(String v) {
    _debounce?.cancel();
    context.read<Shop>().addRecentSearch(v);
    setState(() => _q = v);
  }

  void _pick(String v) {
    _c.text = v;
    _c.selection = TextSelection.collapsed(offset: v.length);
    _submit(v);
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<Shop>();
    final results = sortProducts(shop.search(_q), _sort);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 8, 16, 8),
            child: Row(
              children: [
                GlassIconButton(
                  icon: Iconsax.arrow_left_2,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Hero(
                    tag: 'search-bar',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Glass(
                        radius: 22,
                        opacity: 0.1,
                        child: TextField(
                          controller: _c,
                          focusNode: _focus,
                          onChanged: _onChanged,
                          onSubmitted: _submit,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search products, brands…',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.violetLight,
                            ),
                            suffixIcon: _c.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Iconsax.close_circle,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _debounce?.cancel();
                                      _c.clear();
                                      setState(() => _q = '');
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _q.trim().isEmpty
                  ? _Suggestions(
                      key: const ValueKey('s'),
                      recent: shop.recentSearches,
                      trending: _trending,
                      onPick: _pick,
                      onClear: shop.clearRecent,
                    )
                  : results.isEmpty
                  ? EmptyState(
                      key: const ValueKey('e'),
                      icon: Iconsax.search_status,
                      title: 'No matches for “$_q”',
                      message: 'Try a different keyword or browse categories.',
                    )
                  : Column(
                      key: ValueKey('r$_q'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Text(
                            '${results.length} results',
                            style: Txt.small.copyWith(color: AppColors.textDim),
                          ),
                        ),
                        SortChips(
                          value: _sort,
                          onChanged: (m) => setState(() => _sort = m),
                        ),
                        Expanded(
                          child: MasonryGridView.count(
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 40),
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            itemCount: results.length,
                            itemBuilder: (context, i) => ProductCard(
                              product: results[i],
                              heroPrefix: 'search',
                              onTap: () {
                                shop.addRecentSearch(_q);
                                openProduct(context, results[i], 'search');
                              },
                            ).entrance(i),
                          ),
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

class _Suggestions extends StatelessWidget {
  final List<String> recent;
  final List<String> trending;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;
  const _Suggestions({
    super.key,
    required this.recent,
    required this.trending,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String s, IconData icon, int i) =>
        Pressable(
              onTap: () => onPick(s),
              child: GlassTile(
                radius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: AppColors.violetLight),
                    const SizedBox(width: 7),
                    Text(s, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            )
            .animate(delay: (40 * i).ms)
            .fadeIn()
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Text('Recent', style: Txt.h3),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppColors.violetLight),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, s) in recent.indexed) chip(s, Iconsax.clock, i),
            ],
          ),
          const SizedBox(height: 26),
        ],
        Text('Trending now', style: Txt.h3),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, s) in trending.indexed)
              chip(s, Iconsax.status_up, i),
          ],
        ),
        const SizedBox(height: 26),
        Text('Browse categories', style: Txt.h3),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio:
              0.68 / MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
          children: [
            for (final (i, c) in categories.take(12).indexed)
              Pressable(
                onTap: () => go(context, ProductListScreen.category(c.id)),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: GlassTile(
                        radius: 20,
                        tint: c.color,
                        opacity: 0.12,
                        child: Center(child: Icon(c.icon, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ).entrance(i),
          ],
        ),
      ],
    );
  }
}

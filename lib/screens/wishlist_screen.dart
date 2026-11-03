import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../data/shop.dart';
import '../widgets/common.dart';
import '../widgets/product_widgets.dart';
import '../widgets/space_background.dart';
import 'home_screen.dart';
import 'shell.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<Shop>().wishProducts;
    return Column(
      children: [
        TopBar(
          title: 'Wishlist',
          subtitle: items.isEmpty ? null : '${items.length} saved',
          back: false,
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Iconsax.heart,
                  title: 'Nothing saved yet',
                  message:
                      'Tap the heart on any product to keep it here for later.',
                  action: 'Discover products',
                  onAction: () => ShellScope.of(context)?.goTab(0),
                )
              : ParallaxScroll(
                  child: MasonryGridView.count(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 120),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    itemCount: items.length,
                    itemBuilder: (context, i) => ProductCard(
                      key: ValueKey(items[i].id),
                      product: items[i],
                      heroPrefix: 'wish',
                      onTap: () => openProduct(context, items[i], 'wish'),
                    ).entrance(i),
                  ),
                ),
        ),
      ],
    );
  }
}

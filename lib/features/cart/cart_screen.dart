/// MODULE: Cart screen — Cart items with quantity stepper and
/// swipe-to-delete, voucher field, free-delivery progress and price summary.
///
/// Contains: CartScreen, _FreeDeliveryBar, _CartTile, _CouponField,
/// _CouponFieldState, _Summary.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/config/brand_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/state/shop_state.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/product_widgets.dart';
import '../checkout/checkout_screen.dart';
import '../home/home_screen.dart';
import '../shell/main_shell.dart';

class CartScreen extends StatelessWidget {
  /// True when pushed as its own route (shows a back button).
  final bool standalone;
  const CartScreen({super.key, this.standalone = false});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<Shop>();
    final items = shop.cart;
    final body = Column(
      children: [
        TopBar(
          title: 'My Cart',
          subtitle: items.isEmpty ? null : plural(shop.cartCount, 'item'),
          back: standalone,
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Iconsax.shopping_cart,
                  title: 'Your cart is floating empty',
                  message: 'Add something you love — it only takes a tap.',
                  action: 'Start shopping',
                  onAction: () {
                    if (standalone) Navigator.of(context).pop();
                    ShellScope.of(context)?.goTab(0);
                  },
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    standalone ? 30 : 120,
                  ),
                  children: [
                    if (shop.delivery > 0)
                      _FreeDeliveryBar(subtotal: shop.subtotal),
                    for (final (i, c) in items.indexed)
                      _CartTile(c, key: ValueKey(c.product.id)).entrance(i),
                    const SizedBox(height: 8),
                    const _CouponField(),
                    const SizedBox(height: 16),
                    _Summary(shop: shop),
                    const SizedBox(height: 18),
                    GlowButton(
                      label: 'Checkout  ·  ${taka(shop.total)}',
                      icon: Iconsax.card_tick,
                      onTap: () => go(context, const CheckoutScreen()),
                    ),
                  ],
                ),
        ),
      ],
    );
    return standalone ? Scaffold(body: body) : body;
  }
}

class _FreeDeliveryBar extends StatelessWidget {
  final int subtotal;
  const _FreeDeliveryBar({required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final pct = (subtotal / Brand.freeDeliveryOver).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassTile(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.truck_fast, size: 18, color: AppColors.cyan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add ${taka(Brand.freeDeliveryOver - subtotal)} more for FREE delivery',
                    style: Txt.small.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: pct),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem c;
  const _CartTile(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.read<Shop>();
    final p = c.product;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('d${p.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          shop.removeFromCart(p);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Removed ${p.title}'),
                action: SnackBarAction(
                  label: 'UNDO',
                  textColor: AppColors.violetLight,
                  onPressed: () => shop.addToCart(p, c.qty),
                ),
              ),
            );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.rose.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: const Icon(Iconsax.trash, color: Colors.white),
        ),
        child: Pressable(
          scale: 0.98,
          onTap: () => openProduct(context, p, 'cart'),
          child: GlassTile(
            radius: 22,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(
                      tag: 'cart-${p.id}',
                      child: ProductImage(p.thumbnail, padding: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.brand,
                        style: Txt.small.copyWith(color: AppColors.textFaint),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: PriceTag(p, size: 15)),
                          QtyStepper(
                            qty: c.qty,
                            onChanged: (v) => shop.setQty(p, v),
                            size: 28,
                          ),
                        ],
                      ),
                    ],
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

class _CouponField extends StatefulWidget {
  const _CouponField();

  @override
  State<_CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<_CouponField> {
  final _c = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<Shop>();
    if (shop.couponCode != null) {
      return GlassTile(
        radius: 18,
        tint: AppColors.mint,
        opacity: 0.1,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Iconsax.ticket_discount, color: AppColors.mint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${shop.couponCode} applied — you save ${taka(shop.couponDiscount)}',
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(
        begin: const Offset(0.95, 0.95),
        curve: Curves.easeOutBack,
      );
    }
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _c,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Voucher code',
                      prefixIcon: const Icon(Iconsax.ticket_discount, size: 20),
                      errorText: _error,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GlowButton(
                  label: 'Apply',
                  expanded: false,
                  shine: false,
                  height: 54,
                  onTap: () {
                    final ok = shop.applyCoupon(_c.text);
                    HapticFeedback.mediumImpact();
                    setState(() => _error = ok ? null : 'Invalid voucher code');
                  },
                ),
              ],
            ),
          ],
        )
        .animate(target: _error == null ? 0 : 1)
        .shakeX(hz: 5, amount: 6, duration: 400.ms);
  }
}

class _Summary extends StatelessWidget {
  final Shop shop;
  const _Summary({required this.shop});

  @override
  Widget build(BuildContext context) {
    Widget row(String l, int v, {Color? color, bool neg = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(l, style: TextStyle(color: AppColors.textDim)),
          const Spacer(),
          AnimatedCount(
            value: v,
            format: (x) => x == 0 && l == 'Delivery'
                ? 'FREE'
                : '${neg ? '−' : ''}${taka(x)}',
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
    return Glass(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          row('Subtotal', shop.subtotal),
          row(
            'Delivery',
            shop.delivery,
            color: shop.delivery == 0 ? AppColors.mint : null,
          ),
          if (shop.couponDiscount > 0)
            row(
              'Voucher',
              shop.couponDiscount,
              color: AppColors.mint,
              neg: true,
            ),
          if (shop.savings > 0)
            row('You saved', shop.savings, color: AppColors.mint),
          Divider(color: AppColors.glassBorder, height: 22),
          Row(
            children: [
              const Text('Total', style: Txt.h3),
              const Spacer(),
              AnimatedCount(
                value: shop.total,
                format: taka,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5D0FE), Color(0xFFC4B5FD)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

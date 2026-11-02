import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../config/brand.dart';
import '../data/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/product_widgets.dart';
import '../widgets/space_background.dart';
import 'auth_screen.dart';
import 'checkout_screen.dart';
import 'orders_screen.dart';
import 'shell.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<Shop>();
    final name = shop.userName ?? 'Guest';
    final top = MediaQuery.paddingOf(context).top;
    final menu = [
      (
        Iconsax.box,
        'My orders',
        plural(shop.orders.length, 'order'),
        () => go(context, const OrdersScreen()),
      ),
      (
        Iconsax.location,
        'Delivery address',
        shop.address,
        () => showGlassSheet(context, const AddressForm()),
      ),
      (
        Iconsax.heart,
        'Wishlist',
        '${shop.wishlist.length} saved',
        () => ShellScope.of(context)?.goTab(3),
      ),
      (
        Iconsax.ticket_discount,
        'Vouchers',
        Brand.couponCode,
        () => _vouchers(context),
      ),
      (
        Iconsax.message_question,
        'Help centre',
        Brand.supportEmail,
        () => _help(context),
      ),
      (
        Iconsax.info_circle,
        'About ${Brand.appName}',
        'Version 1.0.0',
        () => _about(context),
      ),
    ];
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, top + 16, 16, 120),
      children: [
        // Profile card
        Glass(
          radius: 30,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppColors.violet,
                              AppColors.magenta,
                              AppColors.cyan,
                              AppColors.violet,
                            ],
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 6.seconds),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.void2,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lavender,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Txt.h2),
                    if ((shop.userEmail ?? '').isNotEmpty)
                      Text(
                        shop.userEmail!,
                        style: Txt.small.copyWith(color: AppColors.textDim),
                      ),
                    const SizedBox(height: 8),
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF472B6)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.crown,
                                size: 13,
                                color: Colors.black,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Galaxy member',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(delay: 2.seconds, duration: 1200.ms),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
        const SizedBox(height: 14),
        // Stats
        Row(
          children: [
            _Stat(
              value: shop.orders.length,
              label: 'Orders',
              icon: Iconsax.box,
            ),
            const SizedBox(width: 10),
            _Stat(
              value: shop.wishlist.length,
              label: 'Wishlist',
              icon: Iconsax.heart,
            ),
            const SizedBox(width: 10),
            _Stat(
              value: shop.cartCount,
              label: 'In cart',
              icon: Iconsax.shopping_cart,
            ),
          ],
        ),
        const SizedBox(height: 20),
        for (final (i, m) in menu.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Pressable(
              scale: 0.98,
              onTap: m.$4,
              child: GlassTile(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(m.$1, size: 20, color: AppColors.violetLight),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.$2,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            m.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Txt.small.copyWith(
                              color: AppColors.textDim,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 18,
                      color: AppColors.textFaint,
                    ),
                  ],
                ),
              ),
            ),
          ).entrance(i, baseMs: 150),
        // The subtle animated background is on by default and can be disabled.
        GlassTile(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          child: ValueListenableBuilder<bool>(
            valueListenable: liveNebula,
            builder: (context, live, _) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.violet,
              secondary: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Iconsax.magic_star,
                  size: 20,
                  color: AppColors.violetLight,
                ),
              ),
              title: const Text(
                'Animated space background',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                live ? 'On · gentle 30 fps drift' : 'Off · static space theme',
                style: Txt.small.copyWith(
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w400,
                ),
              ),
              value: live,
              onChanged: shop.setLiveBackground,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Pressable(
          onTap: () {
            shop.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
              (_) => false,
            );
          },
          child: GlassTile(
            radius: 20,
            tint: AppColors.rose,
            opacity: 0.08,
            padding: const EdgeInsets.all(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.logout, size: 20, color: AppColors.rose),
                SizedBox(width: 10),
                Text(
                  'Sign out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.rose,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        const Center(child: BrandWordmark(size: 18)),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Made with 💜 by Group G-10 · IUB',
            style: Txt.small.copyWith(color: AppColors.textFaint, fontSize: 11),
          ),
        ),
      ],
    );
  }

  void _vouchers(BuildContext context) => showGlassSheet(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your vouchers', style: Txt.h2),
        const SizedBox(height: 14),
        GlassTile(
          radius: 20,
          tint: AppColors.magenta,
          opacity: 0.12,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Iconsax.ticket_discount,
                color: AppColors.magenta,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${Brand.couponPercent}% OFF', style: Txt.h2),
                    Text(
                      'Up to ${taka(Brand.couponMaxDiscount)} · code ${Brand.couponCode}',
                      style: Txt.small.copyWith(color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _help(BuildContext context) => showGlassSheet(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Help centre', style: Txt.h2),
        const SizedBox(height: 10),
        for (final (q, a) in [
          (
            'How long does delivery take?',
            'Dhaka: 1–2 days. Outside Dhaka: 3–5 days.',
          ),
          (
            'Can I pay cash?',
            'Yes — cash on delivery is available nationwide.',
          ),
          (
            'How do returns work?',
            'Return any item within 7 days from My Orders.',
          ),
        ])
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              iconColor: AppColors.violetLight,
              collapsedIconColor: AppColors.textDim,
              title: Text(
                q,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(a, style: TextStyle(color: AppColors.textDim)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Email ${Brand.supportEmail} · Hotline ${Brand.supportPhone}',
          style: Txt.small.copyWith(color: AppColors.violetLight),
        ),
      ],
    ),
  );

  void _about(BuildContext context) => showGlassSheet(
    context,
    Column(
      children: [
        const BrandMark(size: 100),
        const BrandWordmark(size: 28),
        const SizedBox(height: 8),
        Text(
          Brand.banglaTagline,
          style: Txt.bangla.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.lavender,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'A premium e-commerce experience built with Flutter — GPU shaders, glassmorphism and physics-based motion.',
          textAlign: TextAlign.center,
          style: Txt.body.copyWith(color: AppColors.textDim),
        ),
        const SizedBox(height: 10),
        Text(
          'CSE 464 · Group G-10 · Version 1.0.0',
          style: Txt.small.copyWith(color: AppColors.textFaint),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  const _Stat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassTile(
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.violetLight),
            const SizedBox(height: 6),
            AnimatedCount(
              value: value,
              format: (v) => '$v',
              style: Txt.h2,
              gradient: AppColors.textGradient,
            ),
            Text(label, style: Txt.small.copyWith(color: AppColors.textDim)),
          ],
        ),
      ),
    );
  }
}

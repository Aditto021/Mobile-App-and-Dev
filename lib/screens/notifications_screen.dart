import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../config/brand.dart';
import '../data/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/product_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Iconsax.flash, AppColors.magenta, 'Flash Sale is live ⚡', 'Up to 25% off phones & gadgets — ends soon.', '2m'),
      (
        Iconsax.ticket_discount,
        AppColors.gold,
        'Welcome gift 🎁',
        'Use ${Brand.couponCode} for ${Brand.couponPercent}% off your first order.',
        '1h',
      ),
      (
        Iconsax.truck_fast,
        AppColors.cyan,
        'Free delivery weekend',
        'Free delivery on orders over ${taka(Brand.freeDeliveryOver)}.',
        '1d',
      ),
    ];
    return Scaffold(
      body: Column(
        children: [
          const TopBar(title: 'Notifications'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                for (final (i, n) in items.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassTile(
                      radius: 20,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: n.$2.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(n.$1, color: n.$2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.$3, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  n.$4,
                                  style: Txt.small.copyWith(color: AppColors.textDim, fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                          Text(n.$5, style: Txt.small.copyWith(color: AppColors.textFaint)),
                        ],
                      ),
                    ),
                  ).entrance(i),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

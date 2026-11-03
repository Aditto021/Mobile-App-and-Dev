import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/product_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Order status advances with time — refresh so tracking feels live.
    _tick = Timer.periodic(const Duration(seconds: 10), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<Shop>().orders;
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'My Orders',
            subtitle: orders.isEmpty ? null : plural(orders.length, 'order'),
          ),
          Expanded(
            child: orders.isEmpty
                ? EmptyState(
                    icon: Iconsax.box,
                    title: 'No orders yet',
                    message: 'When you place an order, you can track it here in real time.',
                    action: 'Go shopping',
                    onAction: () => Navigator.of(context).pop(),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _OrderCard(orders[i]).entrance(i),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order o;
  const _OrderCard(this.o);

  static const _steps = [
    (Iconsax.receipt_item, 'Placed'),
    (Iconsax.box, 'Packed'),
    (Iconsax.truck_fast, 'Shipped'),
    (Iconsax.home_2, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = o.status.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Glass(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${o.id}', style: Txt.h3),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (s == 3 ? AppColors.mint : AppColors.violetLight)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _steps[s].$2,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: s == 3 ? AppColors.mint : AppColors.violetLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${plural(o.lines.length, 'item')} · ${taka(o.total)} · ${o.payment}',
              style: Txt.small.copyWith(color: AppColors.textDim),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final l in o.lines)
                    Container(
                      width: 54,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ProductImage(l.thumbnail, padding: 4),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Tracking timeline
            Row(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  Column(
                    children: [
                      AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: i <= s ? AppColors.brandGradient : null,
                              color: i <= s
                                  ? null
                                  : Colors.white.withValues(alpha: 0.06),
                              boxShadow: i == s
                                  ? [
                                      BoxShadow(
                                        color: AppColors.magenta.withValues(
                                          alpha: 0.7,
                                        ),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              _steps[i].$1,
                              size: 17,
                              color: i <= s
                                  ? Colors.white
                                  : AppColors.textFaint,
                            ),
                          )
                          .animate(
                            target: i == s && s < 3 ? 1 : 0,
                            onPlay: (c) => c.repeat(reverse: true),
                          )
                          .scaleXY(
                            end: 1.12,
                            duration: 900.ms,
                            curve: Curves.easeInOut,
                          ),
                      const SizedBox(height: 5),
                      Text(
                        _steps[i].$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: i <= s ? AppColors.text : AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                  if (i < _steps.length - 1)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Stack(
                          children: [
                            Container(
                              height: 3,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 700),
                              widthFactor: i < s ? 1 : 0,
                              child: Container(
                                height: 3,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
            if (s < 3)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Live demo: status advances every minute',
                  style: Txt.small.copyWith(
                    color: AppColors.textFaint,
                    fontSize: 10.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

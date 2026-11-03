import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../data/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/fly_to_cart.dart';
import '../widgets/glass.dart';
import '../services/app_updates.dart';
import '../services/display_performance.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'wishlist_screen.dart';

/// Lets nested screens switch tabs (e.g. "Start shopping" from an empty cart).
class ShellScope extends InheritedWidget {
  final ValueChanged<int> goTab;
  const ShellScope({super.key, required this.goTab, required super.child});

  static ShellScope? of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => false;
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onResume());
  }

  void _onResume() {
    if (!mounted) return;
    DisplayPerformance.configure();
    checkForAppUpdates(context, automatic: true);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  int _tab = 0;
  final _visited = <int>{0};

  void _go(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      HomeScreen(),
      CategoriesScreen(),
      CartScreen(),
      WishlistScreen(),
      AccountScreen(),
    ];
    return ShellScope(
      goTab: _go,
      child: PopScope(
        canPop: _tab == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _go(0);
        },
        child: Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              for (var i = 0; i < pages.length; i++)
                // Tabs build lazily, stay alive, and cross-fade with depth.
                IgnorePointer(
                  ignoring: i != _tab,
                  child: AnimatedOpacity(
                    opacity: i == _tab ? 1 : 0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                    child: AnimatedScale(
                      scale: i == _tab ? 1 : 0.97,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      child: TickerMode(
                        enabled: i == _tab,
                        child: _visited.contains(i)
                            ? RepaintBoundary(child: pages[i])
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _NavBar(index: _tab, onTap: _go),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  static const _items = [
    (Iconsax.home_2, 'Home'),
    (Iconsax.category, 'Explore'),
    (Iconsax.shopping_cart, 'Cart'),
    (Iconsax.heart, 'Wishlist'),
    (Iconsax.user, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final count = context.select<Shop, int>((s) => s.cartCount);
    final wish = context.select<Shop, int>((s) => s.wishlist.length);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
      child: Glass(
        radius: 30,
        blur: 26,
        backing: 0.82,
        opacity: 0.13,
        tint: const Color(0xFFC4B5FD),
        child: SizedBox(
          height: 68,
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth / _items.length;
              return Stack(
                children: [
                  // Sliding glow indicator.
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    left: w * index + 8,
                    top: 8,
                    width: w - 16,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.violet.withValues(alpha: 0.44),
                            AppColors.indigo.withValues(alpha: 0.34),
                            AppColors.cyan.withValues(alpha: 0.20),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withValues(alpha: 0.34),
                            blurRadius: 18,
                          ),
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.10),
                            blurRadius: 22,
                            offset: const Offset(5, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTap(i),
                            child: _NavIcon(
                              icon: _items[i].$1,
                              label: _items[i].$2,
                              active: i == index,
                              badge: i == 2 ? count : (i == 3 ? wish : 0),
                              isCart: i == 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1.5,
      duration: 800.ms,
      curve: Curves.easeOutCubic,
      delay: 300.ms,
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final int badge;
  final bool isCart;
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.active,
    required this.badge,
    required this.isCart,
  });

  @override
  Widget build(BuildContext context) {
    Widget ic = Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedScale(
          scale: active ? 1.12 : 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          child: Icon(
            icon,
            size: 23,
            color: active ? Colors.white : AppColors.textDim,
          ),
        ),
        if (badge > 0)
          Positioned(right: -10, top: -7, child: CountBadge(count: badge)),
      ],
    );
    if (isCart) ic = CartTarget(child: ic);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ic,
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: active
              ? Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.5)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

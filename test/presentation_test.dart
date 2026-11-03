import 'dart:io';
import 'dart:ui' as ui;

import 'package:feriwala/data/shop.dart';
import 'package:feriwala/screens/account_screen.dart';
import 'package:feriwala/screens/auth_screen.dart';
import 'package:feriwala/screens/cart_screen.dart';
import 'package:feriwala/screens/checkout_screen.dart';
import 'package:feriwala/screens/home_screen.dart';
import 'package:feriwala/screens/categories_screen.dart';
import 'package:feriwala/screens/wishlist_screen.dart';
import 'package:feriwala/screens/orders_screen.dart';
import 'package:feriwala/screens/order_success_screen.dart';
import 'package:feriwala/screens/search_screen.dart';
import 'package:feriwala/screens/onboarding_screen.dart';
import 'package:feriwala/screens/product_detail_screen.dart';
import 'package:feriwala/screens/splash_screen.dart';
import 'package:feriwala/theme/app_theme.dart';
import 'package:feriwala/widgets/space_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Poppins', 'HindSiliguri']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    for (final font in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/iconsax_flutter/FlutterIconsax':
          'packages/iconsax_flutter/fonts/FlutterIconsax.ttf',
    }.entries) {
      final loader = FontLoader(font.key)..addFont(rootBundle.load(font.value));
      await loader.load();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => '${Directory.current.path}/build/qa/cache',
        );
  });

  for (final scale in [1.0, 1.4]) {
    for (final screen in [
      'splash',
      'onboarding',
      'auth',
      'home',
      'cart',
      'checkout',
      'account',
      'product',
      'categories',
      'wishlist',
      'orders',
      'success',
      'search',
    ]) {
      testWidgets('$screen fits a compact phone at text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final shop = Shop();
        await tester.runAsync(shop.load);
        shop.signIn('Aditi Rahman', 'aditi@example.com');
        shop.addToCart(shop.products.first, 2);
        final order = shop.placeOrder('Cash on delivery');
        shop.addToCart(shop.products.first, 2);
        if (screen == 'splash') shop.ready = false;
        final page = switch (screen) {
          'splash' => const SplashScreen(),
          'onboarding' => const OnboardingScreen(),
          'auth' => const AuthScreen(),
          'home' => const HomeScreen(),
          'cart' => const CartScreen(),
          'checkout' => const CheckoutScreen(),
          'account' => const AccountScreen(),
          'categories' => const CategoriesScreen(),
          'wishlist' => const WishlistScreen(),
          'orders' => const OrdersScreen(),
          'success' => OrderSuccessScreen(order: order),
          'search' => const SearchScreen(),
          _ => ProductDetailScreen(
            product: shop.products.first,
            heroTag: 'qa-product',
          ),
        };
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: shop,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                  key: boundary,
                  child: SpaceBackground(child: child!),
                ),
              ),
              home: Scaffold(body: page),
            ),
          ),
        );
        if (screen == 'splash') {
          await tester.runAsync(() => precacheImage(
            const ResizeImage(AssetImage('assets/brand/feriwala_cycle_vendor.png'), width: 1024),
            tester.element(find.byType(SplashScreen))));
        }
        await tester.pump(const Duration(milliseconds: 700));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 200));
        if (screen == 'splash') {
          await tester.pump(const Duration(milliseconds: 1400));
        }
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);
        if (scale == 1.0) {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final picture = await render.toImage(pixelRatio: 1.5);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final folder = Directory('build/qa')..createSync(recursive: true);
            await File('${folder.path}/$screen.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(seconds: 15));
        shop.dispose();
      });
    }
  }
}

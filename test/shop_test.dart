import 'package:feriwala/core/config/brand_config.dart';
import 'package:feriwala/data/state/shop_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cart rejects nonpositive additions and caps quantities', () async {
    final shop = Shop();
    await shop.load();
    final product = shop.products.first;
    shop.addToCart(product, 0);
    shop.addToCart(product, -2);
    expect(shop.cart, isEmpty);
    shop.addToCart(product, 200);
    expect(shop.qtyOf(product.id), 99);
    shop.setQty(product, 2);
    shop.addToCart(product, -3);
    expect(shop.qtyOf(product.id), 2);
    shop.setQty(product, 0);
    expect(shop.total, 0);
    shop.dispose();
  });

  test('catalogue views are not cached empty before loading', () async {
    final shop = Shop();
    expect(shop.flashSale, isEmpty);
    expect(
      shop.inCategory(shop.products.firstOrNull?.category ?? 'x'),
      isEmpty,
    );
    await shop.load();
    final category = shop.products.first.category;
    expect(shop.flashSale, isNotEmpty);
    expect(shop.topRated, isNotEmpty);
    expect(shop.forYou, hasLength(shop.products.length));
    expect(shop.inCategory(category), isNotEmpty);
    expect(
      shop.inCategory(category).every((p) => p.category == category),
      isTrue,
    );
    shop.dispose();
  });

  test('voucher and cart survive restart and clear after checkout', () async {
    final shop = Shop();
    await shop.load();
    shop.addToCart(shop.products.first, 2);
    expect(shop.applyCoupon(' ${Brand.couponCode.toLowerCase()} '), isTrue);
    final restored = Shop();
    await restored.load();
    expect(restored.cartCount, 2);
    expect(restored.couponCode, Brand.couponCode);
    final expectedTotal = restored.total;
    final order = restored.placeOrder('Cash on delivery');
    expect(order.total, expectedTotal);
    final afterCheckout = Shop();
    await afterCheckout.load();
    expect(afterCheckout.cart, isEmpty);
    expect(afterCheckout.couponCode, isNull);
    expect(afterCheckout.orders, hasLength(1));
    shop.dispose();
    restored.dispose();
    afterCheckout.dispose();
  });

  test('empty cart cannot produce an order', () {
    final shop = Shop();
    expect(() => shop.placeOrder('Cash on delivery'), throwsStateError);
    expect(shop.orders, isEmpty);
    shop.dispose();
  });

  test('damaged wishlist and cart do not hide valid order history', () async {
    final first = Shop();
    await first.load();
    first.addToCart(first.products.first);
    first.placeOrder('Cash on delivery');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('wishlist', [
      'broken-id',
      '${first.products.first.id}',
    ]);
    await prefs.setString('cart', '{invalid json');
    final restored = Shop();
    await restored.load();
    expect(restored.ready, isTrue);
    expect(restored.cart, isEmpty);
    expect(restored.wishlist, {first.products.first.id});
    expect(restored.orders, hasLength(1));
    first.dispose();
    restored.dispose();
  });

  test('blank saved name and repeated search queries are normalized', () async {
    SharedPreferences.setMockInitialValues({'userName': '  '});
    final shop = Shop();
    await shop.load();
    expect(shop.userName, isNull);
    shop.signIn('  ', ' test@example.com ');
    expect(shop.userName, 'Shopper');
    expect(shop.userEmail, 'test@example.com');
    shop.addRecentSearch('Phone');
    shop.addRecentSearch('phone');
    expect(shop.recentSearches, ['phone']);
    shop.dispose();
  });
}

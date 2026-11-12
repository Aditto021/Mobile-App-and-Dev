/// MODULE: API tests — runs every endpoint in-process (no network) against
/// the real catalogue and a temporary data file.
library;

import 'dart:convert';
import 'dart:io';

import 'package:feriwala_server/feriwala_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const strong = 'Secret#123';

void main() {
  late Catalogue catalogue;
  late Store store;
  late Handler handler;
  late DateTime now;
  late Directory tmp;

  setUpAll(() async {
    catalogue = await Catalogue.load('../assets/data/products.json');
  });

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('feriwala_api_');
    store = await Store.open('${tmp.path}/db.json');
    now = DateTime(2026, 11, 12, 10);
    handler = ShopServer(catalogue, store, clock: () => now).handler;
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<(int, dynamic)> call(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final response = await handler(
      Request(
        method,
        Uri.parse('http://api.test$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {'authorization': ?(token == null ? null : 'Bearer $token')},
      ),
    );
    final text = await response.readAsString();
    return (response.statusCode, text.isEmpty ? null : jsonDecode(text));
  }

  Future<String> signUp([String email = 'rahim@example.com']) async {
    final (status, body) = await call(
      'POST',
      '/auth/register',
      body: {'name': 'Rahim Uddin', 'email': email, 'password': strong},
    );
    expect(status, 201, reason: '$body');
    return body['token'] as String;
  }

  Map<String, dynamic> product(bool Function(Map<String, dynamic>) test) =>
      catalogue.items.firstWhere(test);

  group('rules', () {
    test('delivery is free from ৳2,000 and the voucher caps at ৳1,500', () {
      expect(quoteFor([]).total, 0);
      final small = quoteFor([(price: 500, originalPrice: 600, qty: 2)]);
      expect(small.delivery, 60);
      expect(small.savings, 200);
      expect(small.total, 1060);
      final big = quoteFor([
        (price: 20000, originalPrice: 20000, qty: 1),
      ], coupon: ' feriwala10 ');
      expect(big.delivery, 0);
      expect(big.discount, 1500);
      expect(big.total, 18500);
      expect(
        quoteFor([
          (price: 1000, originalPrice: 1000, qty: 1),
        ], coupon: 'X').discount,
        0,
      );
    });
  });

  group('catalogue', () {
    test('health, categories and paging', () async {
      final (_, health) = await call('GET', '/health');
      expect(health['products'], catalogue.items.length);

      final (_, cats) = await call('GET', '/categories');
      final counted = (cats['items'] as List).fold<int>(
        0,
        (a, c) => a + (c['count'] as int),
      );
      expect(counted, catalogue.items.length);

      final (_, page2) = await call('GET', '/products?limit=10&page=2');
      expect(page2['total'], catalogue.items.length);
      expect(page2['items'], hasLength(10));
      expect(page2['items'][0]['id'], catalogue.items[10]['id']);
    });

    test('filter, search and sort', () async {
      final (_, phones) = await call(
        'GET',
        '/products?category=smartphones&sort=price-asc&limit=500',
      );
      final items = (phones['items'] as List).cast<Map>();
      expect(items, isNotEmpty);
      expect(items.every((p) => p['category'] == 'smartphones'), isTrue);
      for (var i = 1; i < items.length; i++) {
        expect(items[i]['price'], greaterThanOrEqualTo(items[i - 1]['price']));
      }

      final brand = catalogue.items.first['brand'] as String;
      final (_, found) = await call(
        'GET',
        '/products?q=${Uri.encodeQueryComponent(brand.toLowerCase())}',
      );
      expect(found['total'], greaterThan(0));

      final (status, _) = await call('GET', '/products?sort=nonsense');
      expect(status, 400);
      final (missing, err) = await call('GET', '/products/1');
      expect(missing, 404);
      expect(err['error']['code'], 'not_found');
    });

    test('voucher check', () async {
      final (_, ok) = await call(
        'POST',
        '/coupons/validate',
        body: {'code': 'feriwala10', 'subtotal': 30000},
      );
      expect(ok['valid'], isTrue);
      expect(ok['discount'], 1500);
      final (_, bad) = await call(
        'POST',
        '/coupons/validate',
        body: {'code': 'FREE'},
      );
      expect(bad['valid'], isFalse);
    });
  });

  group('accounts', () {
    test('register, sign in, profile and sign out', () async {
      final token = await signUp('Rahim@Example.com');
      final (_, me) = await call('GET', '/me', token: token);
      expect(me['email'], 'rahim@example.com');
      expect(me.containsKey('hash'), isFalse);

      final (dup, dupBody) = await call(
        'POST',
        '/auth/register',
        body: {
          'name': 'Rahim',
          'email': 'rahim@example.com',
          'password': strong,
        },
      );
      expect(dup, 409);
      expect(dupBody['error']['code'], 'account_exists');

      final (ok, login) = await call(
        'POST',
        '/auth/login',
        body: {'email': ' RAHIM@example.com ', 'password': strong},
      );
      expect(ok, 200);
      final second = login['token'] as String;

      final (patched, profile) = await call(
        'PATCH',
        '/me',
        token: second,
        body: {
          'name': 'Rahim U',
          'address': 'House 1, Road 2, Dhanmondi, Dhaka',
        },
      );
      expect(patched, 200);
      expect(profile['address'], contains('Dhanmondi'));

      expect((await call('POST', '/auth/logout', token: second)).$1, 204);
      expect((await call('GET', '/me', token: second)).$1, 401);
      expect((await call('GET', '/me', token: token)).$1, 200);
      expect((await call('GET', '/me')).$1, 401);
    });

    test('deleting an account removes all of its data', () async {
      final token = await signUp();
      final id = catalogue.items.first['id'] as int;
      await call('PUT', '/wishlist/$id', token: token);
      await call(
        'POST',
        '/orders',
        token: token,
        body: {
          'payment': 'bKash',
          'address': 'House 12, Road 5, Bashundhara R/A, Dhaka',
          'items': [
            {'productId': id, 'qty': 1},
          ],
        },
      );
      expect((await call('DELETE', '/me', token: token)).$1, 204);
      expect(store.users, isEmpty);
      expect(store.orders, isEmpty);
      expect(store.wishlists, isEmpty);
      expect(store.sessions, isEmpty);
      expect((await call('GET', '/me', token: token)).$1, 401);
      final (again, _) = await call(
        'POST',
        '/auth/login',
        body: {'email': 'rahim@example.com', 'password': strong},
      );
      expect(again, 401);
      // The email can sign up again.
      await signUp();
    });

    test('phone numbers sign in in any common format', () async {
      final (status, _) = await call(
        'POST',
        '/auth/register',
        body: {
          'name': 'Karim',
          'email': '+880 1712-345678',
          'password': strong,
        },
      );
      expect(status, 201);
      final (ok, body) = await call(
        'POST',
        '/auth/login',
        body: {'email': '01712345678', 'password': strong},
      );
      expect(ok, 200);
      expect(body['user']['email'], '01712345678');
    });

    test('weak passwords and bad input are refused', () async {
      for (final body in [
        {'name': 'Rahim', 'email': 'a@b.com', 'password': 'short'},
        {'name': 'Rahim', 'email': 'a@b.com', 'password': 'alllowercase1!'},
        {'name': 'R', 'email': 'a@b.com', 'password': strong},
        {'name': 'Rahim', 'email': 'not-an-email', 'password': strong},
        {'name': 'Rahim', 'email': '0123', 'password': strong},
      ]) {
        final (status, _) = await call('POST', '/auth/register', body: body);
        expect(status, 400, reason: '$body');
      }
      final response = await handler(
        Request('POST', Uri.parse('http://api.test/auth/login'), body: '{oops'),
      );
      expect(response.statusCode, 400);
    });

    test('five wrong passwords lock the account for a minute', () async {
      await signUp();
      Future<int> attempt(String password) async => (await call(
        'POST',
        '/auth/login',
        body: {'email': 'rahim@example.com', 'password': password},
      )).$1;
      for (var i = 0; i < 5; i++) {
        expect(await attempt('Wrong#123'), 401);
      }
      expect(await attempt(strong), 429);
      now = now.add(const Duration(minutes: 2));
      expect(await attempt(strong), 200);
    });

    test('sessions expire after 30 days', () async {
      final token = await signUp();
      now = now.add(const Duration(days: 31));
      expect((await call('GET', '/me', token: token)).$1, 401);
    });
  });

  group('cart and wishlist', () {
    test('cart lines, caps, voucher and quote', () async {
      final token = await signUp();
      final cheap = product((p) => (p['price'] as num) < 1000);
      final id = cheap['id'] as int;

      var (status, cart) = await call(
        'POST',
        '/cart/items',
        token: token,
        body: {'productId': id, 'qty': 2},
      );
      expect(status, 200);
      expect(cart['quote']['subtotal'], (cheap['price'] as int) * 2);
      expect(cart['quote']['delivery'], 60);

      (_, cart) = await call(
        'PATCH',
        '/cart/items/$id',
        token: token,
        body: {'qty': 500},
      );
      expect(cart['items'][0]['qty'], 99);

      (status, _) = await call(
        'POST',
        '/cart/coupon',
        token: token,
        body: {'code': 'NOPE'},
      );
      expect(status, 400);
      (_, cart) = await call(
        'POST',
        '/cart/coupon',
        token: token,
        body: {'code': 'feriwala10'},
      );
      expect(cart['coupon'], 'FERIWALA10');
      expect(cart['quote']['discount'], greaterThan(0));

      (_, cart) = await call(
        'PUT',
        '/cart',
        token: token,
        body: {
          'items': [
            {'productId': id, 'qty': 1},
            {'productId': 1, 'qty': 3}, // not sold: dropped
            {'productId': id, 'qty': 0},
          ],
          'coupon': null,
        },
      );
      expect(cart['items'], hasLength(1));
      expect(cart['coupon'], isNull);

      (_, cart) = await call('DELETE', '/cart/items/$id', token: token);
      expect(cart['items'], isEmpty);
      expect(cart['quote']['total'], 0);
    });

    test('wishlist keeps only real products, once each', () async {
      final token = await signUp();
      final a = catalogue.items[0]['id'] as int;
      final b = catalogue.items[1]['id'] as int;
      var (_, wish) = await call(
        'PUT',
        '/wishlist',
        token: token,
        body: {
          'ids': [a, a, 1, b],
        },
      );
      expect(wish['ids'], [a, b]);
      (_, wish) = await call('DELETE', '/wishlist/$a', token: token);
      expect(wish['ids'], [b]);
      expect((await call('PUT', '/wishlist/1', token: token)).$1, 404);
    });

    test('carts are private to each account', () async {
      final first = await signUp('one@example.com');
      final second = await signUp('two@example.com');
      await call(
        'POST',
        '/cart/items',
        token: first,
        body: {'productId': catalogue.items.first['id']},
      );
      final (_, other) = await call('GET', '/cart', token: second);
      expect(other['items'], isEmpty);
    });
  });

  group('orders', () {
    test(
      'checkout prices on the server, uses stock and clears the cart',
      () async {
        final token = await signUp();
        final p = product((p) => (p['stock'] as num) >= 3);
        final id = p['id'] as int;
        final stockBefore = (await call('GET', '/products/$id')).$2['stock'];

        final (status, order) = await call(
          'POST',
          '/orders',
          token: token,
          body: {
            'payment': 'bKash',
            'address': 'House 12, Road 5, Bashundhara R/A, Dhaka 1229',
            'items': [
              {'productId': id, 'qty': 2},
            ],
            'coupon': 'FERIWALA10',
          },
        );
        expect(status, 201, reason: '$order');
        final price = p['price'] as int;
        final subtotal = price * 2;
        final discount = (subtotal * 0.1).round().clamp(0, 1500);
        final delivery = subtotal >= 2000 ? 0 : 60;
        expect(order['total'], subtotal + delivery - discount);
        expect(order['status'], 'placed');
        expect(order['id'], startsWith('FW'));
        expect(order.containsKey('userId'), isFalse);

        expect(
          (await call('GET', '/products/$id')).$2['stock'],
          stockBefore - 2,
        );
        final (_, cart) = await call('GET', '/cart', token: token);
        expect(cart['items'], isEmpty);
        expect(cart['coupon'], isNull);

        now = now.add(const Duration(minutes: 2));
        final (_, list) = await call('GET', '/orders', token: token);
        expect(list['items'], hasLength(1));
        expect(list['items'][0]['status'], 'shipped');
        final (_, one) = await call(
          'GET',
          '/orders/${order['id']}',
          token: token,
        );
        expect(one['total'], order['total']);

        final stranger = await signUp('other@example.com');
        expect(
          (await call('GET', '/orders/${order['id']}', token: stranger)).$1,
          404,
        );
      },
    );

    test('orders over stock, empty carts and unknown payments fail', () async {
      final token = await signUp();
      final p = product((p) => (p['stock'] as num) < 99);
      final (over, err) = await call(
        'POST',
        '/orders',
        token: token,
        body: {
          'payment': 'Cash on delivery',
          'address': 'House 12, Road 5, Bashundhara R/A, Dhaka',
          'items': [
            {'productId': p['id'], 'qty': (p['stock'] as int) + 1},
          ],
        },
      );
      expect(over, 409);
      expect(err['error']['code'], 'out_of_stock');

      final (empty, _) = await call(
        'POST',
        '/orders',
        token: token,
        body: {
          'payment': 'Cash on delivery',
          'address': 'House 12, Road 5, Bashundhara R/A, Dhaka',
          'items': <Object>[],
        },
      );
      expect(empty, 400);

      final (badPay, _) = await call(
        'POST',
        '/orders',
        token: token,
        body: {
          'payment': 'IOU',
          'address': 'House 12, Road 5, Bashundhara R/A, Dhaka',
          'items': [
            {'productId': p['id'], 'qty': 1},
          ],
        },
      );
      expect(badPay, 400);
      expect((await call('POST', '/orders', body: {})).$1, 401);
    });
  });

  test('everything survives a restart', () async {
    final token = await signUp();
    final id = catalogue.items.first['id'] as int;
    await call('PUT', '/wishlist/$id', token: token);
    await call(
      'POST',
      '/orders',
      token: token,
      body: {
        'payment': 'Nagad',
        'address': 'House 12, Road 5, Bashundhara R/A, Dhaka',
        'items': [
          {'productId': id, 'qty': 1},
        ],
      },
    );
    await store.save();

    final reopened = await Store.open(store.path);
    handler = ShopServer(catalogue, reopened, clock: () => now).handler;
    expect((await call('GET', '/wishlist', token: token)).$2['ids'], [id]);
    expect(
      (await call('GET', '/orders', token: token)).$2['items'],
      hasLength(1),
    );
    final (ok, _) = await call(
      'POST',
      '/auth/login',
      body: {'email': 'rahim@example.com', 'password': strong},
    );
    expect(ok, 200);
    final (_, after) = await call('GET', '/products/$id');
    expect(after['stock'], (catalogue.items.first['stock'] as int) - 1);
  });

  test('CORS preflight and unknown routes', () async {
    final pre = await handler(
      Request('OPTIONS', Uri.parse('http://api.test/cart')),
    );
    expect(pre.statusCode, 204);
    expect(pre.headers['access-control-allow-origin'], '*');
    final (status, body) = await call('GET', '/nope');
    expect(status, 404);
    expect(body['error']['code'], 'not_found');
  });
}

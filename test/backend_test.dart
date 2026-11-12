/// MODULE: Backend tests — the app's Shop talking to the real FeriWala
/// server through Dio, run in-process (no network): sign-up, cart sync
/// across devices, server checkout, refusals and offline fallback.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:feriwala/data/api/api_client.dart';
import 'package:feriwala/data/api/shop_api.dart';
import 'package:feriwala/data/state/shop_state.dart';
import 'package:feriwala_server/feriwala_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;

const password = 'Secret#123';

/// Hands Dio's requests straight to the server's handler.
class InProcessAdapter implements HttpClientAdapter {
  final shelf.Handler handler;

  /// Pretend the server can't be reached.
  bool down = false;

  InProcessAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (down) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'server down',
      );
    }
    final response = await handler(
      shelf.Request(
        options.method,
        options.uri,
        headers: {for (final e in options.headers.entries) e.key: '${e.value}'},
        body: requestStream,
      ),
    );
    return ResponseBody(
      response.read().map(Uint8List.fromList),
      response.statusCode,
      headers: {
        for (final e in response.headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InProcessAdapter adapter;
  final shops = <Shop>[];

  Future<Shop> device() async {
    SharedPreferences.setMockInitialValues({});
    final shop = Shop(api: ShopApi('http://api.test', adapter: adapter));
    shops.add(shop);
    await shop.load();
    await shop.refresh();
    return shop;
  }

  setUp(() async {
    final catalogue = await Catalogue.load('assets/data/products.json');
    adapter = InProcessAdapter(
      ShopServer(catalogue, await Store.open()).handler,
    );
  });

  tearDown(() {
    for (final s in shops) {
      s.dispose();
    }
    shops.clear();
  });

  test('account, cart and wishlist follow the shopper to a new device, '
      'and the server prices the order', () async {
    final phone = await device();
    expect(phone.online, isTrue);
    expect(
      await phone.register('Rahim Uddin', 'rahim@example.com', password),
      AuthResult.online,
    );
    expect(phone.hasAccount, isTrue);
    final p = phone.products.firstWhere((p) => p.stock >= 2);
    phone
      ..addToCart(p, 2)
      ..toggleWish(p);
    expect(phone.applyCoupon(' feriwala10 '), isTrue);
    await phone.flush();

    final tablet = await device();
    expect(
      await tablet.login('RAHIM@example.com', password, offlineName: 'x'),
      AuthResult.online,
    );
    expect(tablet.userName, 'Rahim Uddin');
    expect(tablet.qtyOf(p.id), 2);
    expect(tablet.couponCode, 'FERIWALA10');
    expect(tablet.isWished(p.id), isTrue);

    final expected = tablet.total;
    final order = await tablet.checkout('bKash');
    expect(order.id, startsWith('FW'));
    expect(order.total, expected);
    expect(tablet.cart, isEmpty);
    expect(tablet.couponCode, isNull);

    await tablet.refresh();
    expect(tablet.byId(p.id)!.stock, p.stock - 2);
    await phone.refresh();
    expect(phone.orders.map((o) => o.id), contains(order.id));
  });

  test('a wrong password shows the server\'s message', () async {
    final shop = await device();
    await shop.register('Rahim Uddin', 'rahim@example.com', password);
    shop.signOut();
    expect(shop.hasAccount, isFalse);
    await expectLater(
      shop.login('rahim@example.com', 'Wrong#123', offlineName: 'x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Wrong'),
        ),
      ),
    );
    expect(shop.hasAccount, isFalse);
    expect(shop.userName, isNull);
  });

  test('a sold-out refusal keeps the cart for the shopper to fix', () async {
    final shop = await device();
    await shop.register('Rahim Uddin', 'rahim@example.com', password);
    final p = shop.products.firstWhere((p) => p.stock < 98);
    shop.addToCart(p, p.stock + 1);
    await expectLater(
      shop.checkout('Cash on delivery'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'out_of_stock'),
      ),
    );
    expect(shop.qtyOf(p.id), p.stock + 1);
    expect(shop.orders, isEmpty);
  });

  test(
    'with the server down the app still signs in and takes orders',
    () async {
      final shop = await device();
      adapter.down = true;
      expect(
        await shop.login('rahim@example.com', password, offlineName: 'Rahim'),
        AuthResult.offline,
      );
      expect(shop.hasAccount, isFalse);
      expect(shop.userName, 'Rahim');
      shop.addToCart(shop.products.first);
      final order = await shop.checkout('Cash on delivery');
      expect(shop.orders.single.id, order.id);
      await shop.refresh();
      expect(shop.online, isFalse);
    },
  );

  test(
    'deleting the account removes it from the server and the phone',
    () async {
      final shop = await device();
      await shop.register('Rahim Uddin', 'rahim@example.com', password);
      shop.addToCart(shop.products.first);
      await shop.checkout('bKash');
      await shop.deleteAccount();
      expect(shop.hasAccount, isFalse);
      expect(shop.userName, isNull);
      expect(shop.orders, isEmpty);
      await expectLater(
        shop.login('rahim@example.com', password, offlineName: 'x'),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('signing out of an account clears its data from the device', () async {
    final shop = await device();
    await shop.register('Rahim Uddin', 'rahim@example.com', password);
    shop.addToCart(shop.products.first);
    await shop.flush();
    shop.signOut();
    expect(shop.cart, isEmpty);
    expect(shop.wishlist, isEmpty);
    expect(shop.userName, isNull);

    await shop.login('rahim@example.com', password, offlineName: 'x');
    expect(shop.qtyOf(shop.products.first.id), 1);
  });
}

/// MODULE: Shop API — one typed method per server endpoint the app uses,
/// turning JSON into the app's models.
///
/// Contains: ApiUser, ApiSession, RemoteCart, ShopApi.
library;

import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_client.dart';

typedef ApiUser = ({String name, String email, String address});
typedef ApiSession = ({String token, ApiUser user});
typedef RemoteCart = ({Map<int, int> items, String? coupon});

class ShopApi {
  final ApiClient client;
  ShopApi(String baseUrl, {HttpClientAdapter? adapter})
    : client = ApiClient(baseUrl, adapter: adapter);

  /// The API for this build, or null when it runs without a server.
  static ShopApi? fromConfig() {
    final url = ApiConfig.baseUrl;
    return url == null ? null : ShopApi(url);
  }

  set token(String? t) => client.token = t;

  // ---- Catalogue ----

  Future<List<Product>> products() async {
    final data = await client.get('/products', query: {'limit': 500});
    return [
      for (final p in (data['items'] as List))
        Product.fromJson(p as Map<String, dynamic>),
    ];
  }

  // ---- Account ----

  static ApiUser _user(dynamic j) => (
    name: j['name'] as String,
    email: j['email'] as String,
    address: j['address'] as String? ?? '',
  );

  static ApiSession _session(dynamic j) =>
      (token: j['token'] as String, user: _user(j['user']));

  Future<ApiSession> register(
    String name,
    String email,
    String password,
  ) async => _session(
    await client.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    }),
  );

  Future<ApiSession> login(String email, String password) async => _session(
    await client.post('/auth/login', {'email': email, 'password': password}),
  );

  /// Ends [token]'s session on the server.
  Future<void> logout(String token) => client.post(
    '/auth/logout',
    null,
    Options(headers: {'authorization': 'Bearer $token'}),
  );

  Future<ApiUser> me() async => _user(await client.get('/me'));

  Future<ApiUser> updateMe({String? name, String? address}) async =>
      _user(await client.patch('/me', {'name': ?name, 'address': ?address}));

  /// Deletes the signed-in account and all its data on the server.
  Future<void> deleteAccount() => client.delete('/me');

  // ---- Cart & wishlist ----

  static RemoteCart _cart(dynamic j) => (
    items: {
      for (final l in (j['items'] as List))
        l['productId'] as int: l['qty'] as int,
    },
    coupon: j['coupon'] as String?,
  );

  Future<RemoteCart> cart() async => _cart(await client.get('/cart'));

  /// Replaces the saved cart with [items] (productId → qty) and [coupon].
  Future<RemoteCart> putCart(Map<int, int> items, String? coupon) async =>
      _cart(
        await client.put('/cart', {
          'items': [
            for (final e in items.entries) {'productId': e.key, 'qty': e.value},
          ],
          'coupon': coupon,
        }),
      );

  Future<List<int>> wishlist() async =>
      ((await client.get('/wishlist'))['ids'] as List).cast<int>();

  Future<List<int>> putWishlist(Iterable<int> ids) async =>
      ((await client.put('/wishlist', {'ids': ids.toList()}))['ids'] as List)
          .cast<int>();

  // ---- Orders ----

  Future<List<Order>> orders() async => [
    for (final o in ((await client.get('/orders'))['items'] as List))
      Order.fromJson(o as Map<String, dynamic>),
  ];

  /// Places an order for exactly these lines; the server checks stock and
  /// works out the total.
  Future<Order> placeOrder({
    required Map<int, int> items,
    required String? coupon,
    required String payment,
    required String address,
  }) async => Order.fromJson(
    await client.post('/orders', {
      'items': [
        for (final e in items.entries) {'productId': e.key, 'qty': e.value},
      ],
      'coupon': coupon,
      'payment': payment,
      'address': address,
    }) as Map<String, dynamic>,
  );
}

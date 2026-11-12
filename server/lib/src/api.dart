/// MODULE: API routes — every endpoint the app uses: sign-up / sign-in,
/// profile, catalogue and search, cart with voucher and price quote,
/// wishlist, and orders (stock checked and totals worked out here, never
/// trusted from the phone).
///
/// Contains: ShopServer.
library;

import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'catalogue.dart';
import 'http.dart';
import 'rules.dart';
import 'store.dart';

/// Order status names, one step per minute after the order is placed —
/// the same live-tracking demo the app shows.
const orderStatuses = ['placed', 'packed', 'shipped', 'delivered'];

class ShopServer {
  final Catalogue catalogue;
  final Store store;

  /// Current time; tests pass a fake clock.
  final DateTime Function() clock;

  /// Wrong-password count per login, for the short lock-out.
  final _failures = <String, ({int count, DateTime until})>{};

  late final Router _router = _routes();

  ShopServer(this.catalogue, this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  /// The full HTTP handler: CORS, JSON errors, then the routes.
  Handler get handler => const Pipeline()
      .addMiddleware(cors())
      .addMiddleware(handleErrors())
      .addHandler(_router.call);

  Router _routes() {
    final r = Router(
      notFoundHandler: (_) =>
          throw const ApiError.notFound('No such endpoint.'),
    );

    r.get('/', _health);
    r.get('/health', _health);

    // Catalogue — open to everyone.
    r.get('/categories', _categories);
    r.get('/products', _products);
    r.get('/products/<id|[0-9]+>', (Request q, String id) {
      return jsonOk(_productJson(_product(int.parse(id))));
    });
    r.post('/coupons/validate', _validateCoupon);

    // Accounts.
    r.post('/auth/register', _register);
    r.post('/auth/login', _login);
    r.post('/auth/logout', _logout);
    r.get('/me', (Request q) => jsonOk(_user(q).toPublicJson()));
    r.patch('/me', _updateMe);
    r.delete('/me', _deleteMe);

    // Cart.
    r.get('/cart', (Request q) => jsonOk(_cartJson(_cartOf(_user(q)))));
    r.put('/cart', _replaceCart);
    r.post('/cart/items', _addItem);
    r.patch('/cart/items/<id|[0-9]+>', _setItem);
    r.delete('/cart/items/<id|[0-9]+>', _removeItem);
    r.post('/cart/coupon', _applyCoupon);
    r.delete('/cart/coupon', _removeCoupon);

    // Wishlist.
    r.get('/wishlist', (Request q) => jsonOk({'ids': _wishOf(_user(q))}));
    r.put('/wishlist', _replaceWishlist);
    r.put('/wishlist/<id|[0-9]+>', _wish);
    r.delete('/wishlist/<id|[0-9]+>', _unwish);

    // Orders.
    r.get('/orders', _orders);
    r.get('/orders/<id>', _order);
    r.post('/orders', _placeOrder);
    return r;
  }

  // ---------------------------------------------------------------- helpers

  /// The signed-in user, from the `Authorization: Bearer <token>` header.
  User _user(Request q) {
    final header = q.headers['authorization'] ?? '';
    if (!header.startsWith('Bearer ')) {
      throw const ApiError.unauthorized('Sign in to continue.');
    }
    final key = Tokens.key(header.substring(7).trim());
    final session = store.sessions[key];
    if (session == null || session.expires.isBefore(clock())) {
      store.sessions.remove(key);
      throw const ApiError.unauthorized();
    }
    final user = store.userById(session.userId);
    if (user == null) throw const ApiError.unauthorized();
    return user;
  }

  String _startSession(User user) {
    final now = clock();
    store.sessions.removeWhere((_, s) => s.expires.isBefore(now));
    final token = Tokens.create();
    store.sessions[Tokens.key(token)] = (
      userId: user.id,
      expires: now.add(Rules.sessionLife),
    );
    return token;
  }

  Map<String, dynamic> _product(int id) =>
      catalogue.byId(id) ??
      (throw const ApiError.notFound('That product is no longer sold.'));

  int stockOf(int id) {
    final p = catalogue.byId(id);
    if (p == null) return 0;
    return max(0, (p['stock'] as num).toInt() - (store.sold[id] ?? 0));
  }

  /// A product as the API shows it: live stock and sales.
  Map<String, dynamic> _productJson(Map<String, dynamic> p) {
    final id = p['id'] as int;
    return {
      ...p,
      'stock': stockOf(id),
      'sold': ((p['sold'] as num?)?.toInt() ?? 0) + (store.sold[id] ?? 0),
    };
  }

  int _id(String raw) => int.parse(raw);

  // ---------------------------------------------------------------- health

  Response _health(Request q) => jsonOk({
    'name': 'FeriWala API',
    'ok': true,
    'products': catalogue.items.length,
    'categories': catalogue.categories.length,
    'time': clock().toIso8601String(),
  });

  // ------------------------------------------------------------- catalogue

  Response _categories(Request q) {
    final counts = <String, int>{};
    for (final p in catalogue.items) {
      counts.update(p['category'] as String, (n) => n + 1, ifAbsent: () => 1);
    }
    return jsonOk({
      'items': [
        for (final c in catalogue.categories) {'id': c, 'count': counts[c]},
      ],
    });
  }

  /// GET /products?category=&q=&ids=1,2&sort=&page=1&limit=20
  ///
  /// sort: price-asc, price-desc, discount, rating, popular (default:
  /// catalogue order).
  Response _products(Request q) {
    final params = q.url.queryParameters;
    Iterable<Map<String, dynamic>> list = catalogue.items;

    final category = params['category']?.trim() ?? '';
    if (category.isNotEmpty) {
      list = list.where((p) => p['category'] == category);
    }
    final ids = (params['ids'] ?? '')
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
    if (ids.isNotEmpty) list = list.where((p) => ids.contains(p['id']));

    final search = params['q']?.trim().toLowerCase() ?? '';
    if (search.isNotEmpty) {
      list = list.where(
        (p) =>
            (p['title'] as String).toLowerCase().contains(search) ||
            (p['brand'] as String).toLowerCase().contains(search) ||
            (p['category'] as String).replaceAll('-', ' ').contains(search),
      );
    }

    final sorted = list.toList();
    int byNum(Map a, Map b, String k) => (b[k] as num).compareTo(a[k] as num);
    switch (params['sort']) {
      case 'price-asc':
        sorted.sort((a, b) => -byNum(a, b, 'price'));
      case 'price-desc':
        sorted.sort((a, b) => byNum(a, b, 'price'));
      case 'discount':
        sorted.sort((a, b) => byNum(a, b, 'discount'));
      case 'rating':
        sorted.sort((a, b) => byNum(a, b, 'rating'));
      case 'popular':
        sorted.sort(
          (a, b) => _productJson(b)['sold'].compareTo(_productJson(a)['sold']),
        );
      case null || '':
        break;
      default:
        throw const ApiError.badRequest(
          'sort must be price-asc, price-desc, discount, rating or popular.',
        );
    }

    final limit = (int.tryParse(params['limit'] ?? '') ?? 20).clamp(1, 500);
    final page = max(1, int.tryParse(params['page'] ?? '') ?? 1);
    return jsonOk({
      'items': [
        for (final p in sorted.skip((page - 1) * limit).take(limit))
          _productJson(p),
      ],
      'total': sorted.length,
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> _validateCoupon(Request q) async {
    final body = await readBody(q);
    final code = body['code'];
    final valid = Rules.isCoupon(code is String ? code : null);
    final subtotal = body['subtotal'] is int ? body['subtotal'] as int : 0;
    return jsonOk({
      'valid': valid,
      'code': valid ? Rules.couponCode : null,
      'percent': valid ? Rules.couponPercent : 0,
      'maxDiscount': valid ? Rules.couponMaxDiscount : 0,
      'discount': valid
          ? quoteFor([
              (
                price: max(0, subtotal),
                originalPrice: max(0, subtotal),
                qty: 1,
              ),
            ], coupon: Rules.couponCode).discount
          : 0,
      'message': valid
          ? '${Rules.couponPercent}% off, up to ৳${Rules.couponMaxDiscount}.'
          : 'Invalid voucher code',
    });
  }

  // -------------------------------------------------------------- accounts

  Future<Response> _register(Request q) async {
    final body = await readBody(q);
    final name = Check.name(body['name']);
    final login = Check.login(body['email']);
    final password = Check.newPassword(body['password']);
    final address =
        body['address'] is String &&
            (body['address'] as String).trim().isNotEmpty
        ? Check.address(body['address'])
        : '';
    if (store.users.containsKey(login)) {
      throw const ApiError.conflict(
        'account_exists',
        'An account with this email or phone already exists. Sign in instead.',
      );
    }
    final salt = Passwords.newSalt();
    final user = User(
      id: store.newUserId(),
      name: name,
      login: login,
      salt: salt,
      hash: Passwords.hash(password, salt),
      address: address,
      created: clock(),
    );
    store.users[login] = user;
    final token = _startSession(user);
    await store.save();
    return jsonOk({'token': token, 'user': user.toPublicJson()}, status: 201);
  }

  Future<Response> _login(Request q) async {
    final body = await readBody(q);
    final login = Check.login(body['email']);
    final password = body['password'] is String
        ? body['password'] as String
        : '';
    final now = clock();
    final record = _failures[login];
    final recent = record != null && record.until.isAfter(now);
    if (recent && record.count >= Rules.maxLoginFailures) {
      throw const ApiError(
        429,
        'locked',
        'Too many wrong passwords. Try again in a minute.',
      );
    }
    final user = store.users[login];
    final bool ok;
    if (user == null) {
      // Hash anyway so an unknown login takes as long as a wrong password.
      Passwords.hash(password, 'no-such-user');
      ok = false;
    } else {
      ok = Passwords.matches(password, user.salt, user.hash);
    }
    if (!ok) {
      _failures[login] = (
        count: (recent ? record.count : 0) + 1,
        until: now.add(Rules.lockout),
      );
      throw const ApiError(
        401,
        'wrong_login',
        'Wrong email/phone or password.',
      );
    }
    _failures.remove(login);
    final token = _startSession(user!);
    await store.save();
    return jsonOk({'token': token, 'user': user.toPublicJson()});
  }

  Future<Response> _logout(Request q) async {
    final header = q.headers['authorization'] ?? '';
    if (header.startsWith('Bearer ')) {
      store.sessions.remove(Tokens.key(header.substring(7).trim()));
      await store.save();
    }
    return Response(204);
  }

  Future<Response> _updateMe(Request q) async {
    final user = _user(q);
    final body = await readBody(q);
    if (body.containsKey('name')) user.name = Check.name(body['name']);
    if (body.containsKey('address')) {
      user.address = Check.address(body['address']);
    }
    await store.save();
    return jsonOk(user.toPublicJson());
  }

  /// Deletes the account and everything kept for it: sessions, cart,
  /// wishlist and order history.
  Future<Response> _deleteMe(Request q) async {
    final user = _user(q);
    store.users.remove(user.login);
    store.sessions.removeWhere((_, s) => s.userId == user.id);
    store.carts.remove(user.id);
    store.wishlists.remove(user.id);
    store.orders.removeWhere((o) => o['userId'] == user.id);
    _failures.remove(user.login);
    await store.save();
    return Response(204);
  }

  // ------------------------------------------------------------------ cart

  CartData _cartOf(User u) => store.carts.putIfAbsent(u.id, CartData.new);

  Map<String, dynamic> _cartJson(CartData cart) {
    final lines = <Map<String, dynamic>>[];
    for (final e in cart.items.entries) {
      final p = catalogue.byId(e.key);
      if (p == null) continue;
      lines.add({
        'productId': e.key,
        'qty': e.value,
        'title': p['title'],
        'thumbnail': p['thumbnail'],
        'price': Catalogue.priceOf(p),
        'originalPrice': Catalogue.originalPriceOf(p),
        'stock': stockOf(e.key),
      });
    }
    final quote = quoteFor([
      for (final l in lines)
        (
          price: l['price'] as int,
          originalPrice: l['originalPrice'] as int,
          qty: l['qty'] as int,
        ),
    ], coupon: cart.coupon);
    return {'items': lines, 'coupon': cart.coupon, 'quote': quote.toJson()};
  }

  /// Replaces the cart's lines with `[{productId, qty}]`. Products no
  /// longer sold and quantities of 0 or less are dropped; the rest are
  /// capped at 99.
  void _setLines(CartData cart, Object? items) {
    if (items is! List) {
      throw const ApiError.badRequest(
        'items must be a list of {productId, qty}.',
      );
    }
    final next = <int, int>{};
    for (final item in items) {
      if (item is! Map || item['productId'] is! int) {
        throw const ApiError.badRequest(
          'items must be a list of {productId, qty}.',
        );
      }
      final id = item['productId'] as int;
      final qty = Check.qty(item['qty']);
      if (qty <= 0 || catalogue.byId(id) == null) continue;
      next[id] = ((next[id] ?? 0) + qty).clamp(1, Rules.maxQty);
    }
    cart.items
      ..clear()
      ..addAll(next);
  }

  void _setCoupon(CartData cart, Object? code) {
    if (code == null) {
      cart.coupon = null;
    } else if (code is String && Rules.isCoupon(code)) {
      cart.coupon = Rules.couponCode;
    } else {
      throw const ApiError.badRequest('Invalid voucher code');
    }
  }

  Future<Response> _replaceCart(Request q) async {
    final cart = _cartOf(_user(q));
    final body = await readBody(q);
    _setLines(cart, body['items'] ?? const []);
    if (body.containsKey('coupon')) _setCoupon(cart, body['coupon']);
    await store.save();
    return jsonOk(_cartJson(cart));
  }

  Future<Response> _addItem(Request q) async {
    final cart = _cartOf(_user(q));
    final body = await readBody(q);
    if (body['productId'] is! int) {
      throw const ApiError.badRequest('productId is required.');
    }
    final id = body['productId'] as int;
    _product(id);
    final qty = Check.qty(body['qty']);
    if (qty <= 0) {
      throw const ApiError.badRequest('Quantity must be 1 or more.');
    }
    cart.items[id] = ((cart.items[id] ?? 0) + qty).clamp(1, Rules.maxQty);
    await store.save();
    return jsonOk(_cartJson(cart));
  }

  Future<Response> _setItem(Request q, String rawId) async {
    final cart = _cartOf(_user(q));
    final id = _id(rawId);
    _product(id);
    final qty = Check.qty((await readBody(q))['qty'], fallback: 0);
    if (qty <= 0) {
      cart.items.remove(id);
    } else {
      cart.items[id] = qty.clamp(1, Rules.maxQty);
    }
    await store.save();
    return jsonOk(_cartJson(cart));
  }

  Future<Response> _removeItem(Request q, String rawId) async {
    final cart = _cartOf(_user(q));
    cart.items.remove(_id(rawId));
    await store.save();
    return jsonOk(_cartJson(cart));
  }

  Future<Response> _applyCoupon(Request q) async {
    final cart = _cartOf(_user(q));
    final code = (await readBody(q))['code'];
    if (code is! String || !Rules.isCoupon(code)) {
      throw const ApiError.badRequest('Invalid voucher code');
    }
    _setCoupon(cart, code);
    await store.save();
    return jsonOk(_cartJson(cart));
  }

  Future<Response> _removeCoupon(Request q) async {
    final cart = _cartOf(_user(q));
    cart.coupon = null;
    await store.save();
    return jsonOk(_cartJson(cart));
  }

  // -------------------------------------------------------------- wishlist

  List<int> _wishOf(User u) => store.wishlists.putIfAbsent(u.id, () => []);

  Future<Response> _replaceWishlist(Request q) async {
    final wish = _wishOf(_user(q));
    final ids = (await readBody(q))['ids'];
    if (ids is! List || ids.any((e) => e is! int)) {
      throw const ApiError.badRequest('ids must be a list of product ids.');
    }
    final next = ids.cast<int>().where((id) => catalogue.byId(id) != null);
    wish
      ..clear()
      ..addAll(next.toSet());
    await store.save();
    return jsonOk({'ids': wish});
  }

  Future<Response> _wish(Request q, String rawId) async {
    final wish = _wishOf(_user(q));
    final id = _id(rawId);
    _product(id);
    if (!wish.contains(id)) wish.add(id);
    await store.save();
    return jsonOk({'ids': wish});
  }

  Future<Response> _unwish(Request q, String rawId) async {
    final wish = _wishOf(_user(q));
    wish.remove(_id(rawId));
    await store.save();
    return jsonOk({'ids': wish});
  }

  // ---------------------------------------------------------------- orders

  /// An order as the API shows it: no owner id, with its current status.
  Map<String, dynamic> _orderJson(Map<String, dynamic> o) {
    final minutes = clock()
        .difference(DateTime.parse(o['date'] as String))
        .inMinutes;
    return {
      for (final e in o.entries)
        if (e.key != 'userId') e.key: e.value,
      'status': orderStatuses[minutes.clamp(0, orderStatuses.length - 1)],
    };
  }

  Response _orders(Request q) {
    final user = _user(q);
    return jsonOk({
      'items': [
        for (final o in store.orders.reversed)
          if (o['userId'] == user.id) _orderJson(o),
      ],
    });
  }

  Response _order(Request q, String id) {
    final user = _user(q);
    for (final o in store.orders) {
      if (o['id'] == id && o['userId'] == user.id) return jsonOk(_orderJson(o));
    }
    throw const ApiError.notFound('No such order.');
  }

  /// POST /orders {payment, address?, items?, coupon?}
  ///
  /// Uses the saved cart, or `items` / `coupon` when sent (so the phone
  /// can check out the cart it shows in one call). Checks stock, prices
  /// everything here, takes the units out of stock and empties the cart.
  Future<Response> _placeOrder(Request q) async {
    final user = _user(q);
    final cart = _cartOf(user);
    final body = await readBody(q);
    if (body.containsKey('items')) _setLines(cart, body['items']);
    if (body.containsKey('coupon')) _setCoupon(cart, body['coupon']);

    final payment = body['payment'];
    if (payment is! String || !Rules.payments.contains(payment)) {
      throw ApiError.badRequest(
        'Choose a payment method: ${Rules.payments.join(', ')}.',
      );
    }
    final sent = body['address'];
    final address = Check.address(
      sent is String && sent.trim().isNotEmpty ? sent : user.address,
    );
    if (cart.items.isEmpty) {
      throw const ApiError.badRequest('Your cart is empty.');
    }

    final lines = <Map<String, dynamic>>[];
    for (final e in cart.items.entries) {
      final p = _product(e.key);
      final left = stockOf(e.key);
      if (e.value > left) {
        throw ApiError.conflict(
          'out_of_stock',
          left == 0
              ? '"${p['title']}" is sold out. Remove it to continue.'
              : 'Only $left left of "${p['title']}". Lower the quantity to continue.',
        );
      }
      lines.add({
        'productId': e.key,
        'title': p['title'],
        'thumbnail': p['thumbnail'],
        'price': Catalogue.priceOf(p),
        'originalPrice': Catalogue.originalPriceOf(p),
        'qty': e.value,
      });
    }
    final quote = quoteFor([
      for (final l in lines)
        (
          price: l['price'] as int,
          originalPrice: l['originalPrice'] as int,
          qty: l['qty'] as int,
        ),
    ], coupon: cart.coupon);

    final now = clock();
    var n = now.millisecondsSinceEpoch % 100000000;
    String id() => '${Rules.orderPrefix}${n.toString().padLeft(8, '0')}';
    while (store.orders.any((o) => o['id'] == id())) {
      n = (n + 1) % 100000000;
    }
    final order = <String, dynamic>{
      'id': id(),
      'userId': user.id,
      'date': now.toIso8601String(),
      'lines': [
        for (final l in lines)
          {
            'productId': l['productId'],
            'title': l['title'],
            'thumbnail': l['thumbnail'],
            'price': l['price'],
            'qty': l['qty'],
          },
      ],
      'subtotal': quote.subtotal,
      'delivery': quote.delivery,
      'discount': quote.discount,
      'savings': quote.savings,
      'total': quote.total,
      'coupon': cart.coupon,
      'payment': payment,
      'address': address,
    };
    store.orders.add(order);
    for (final l in lines) {
      final pid = l['productId'] as int;
      store.sold[pid] = (store.sold[pid] ?? 0) + (l['qty'] as int);
    }
    cart.items.clear();
    cart.coupon = null;
    if (user.address.isEmpty) user.address = address;
    await store.save();
    return jsonOk(_orderJson(order), status: 201);
  }
}

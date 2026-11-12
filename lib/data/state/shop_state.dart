/// MODULE: Shop state (Provider) — The single ChangeNotifier that holds all
/// app state — catalogue, cart, wishlist, orders, account — saves it on the
/// device with shared_preferences and keeps it in step with the FeriWala
/// server (when one is reachable).
///
/// Works offline first: every change shows at once and is saved on the
/// device; with a signed-in account the cart, voucher and wishlist are then
/// sent to the server, and orders are placed (and priced) by the server.
///
/// Contains: AuthResult, Shop.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/brand_config.dart';
import '../../shared/widgets/space_background.dart';
import '../api/api_client.dart';
import '../api/shop_api.dart';
import '../models/models.dart';

/// How a sign-in went: with the server, or on this device only because the
/// server could not be reached.
enum AuthResult { online, offline }

/// All app state: catalogue, cart, wishlist, orders and account.
/// Persisted locally so the app keeps its state across launches.
class Shop extends ChangeNotifier {
  Shop({this.api});

  /// The server, or null to run on the device only (tests, `API_URL=off`).
  final ShopApi? api;

  /// Sign-in token for the server account, if signed in to one.
  String? _token;

  /// Signed in to a server account (not just on this device).
  bool get hasAccount => _token != null;

  /// Whether the last call to the server worked.
  bool online = false;

  Timer? _pushTimer;
  Future<void>? _pushing;
  Future<void>? _refreshing;

  List<Product> products = [];
  final Map<int, CartItem> _cart = {};
  final Set<int> wishlist = {};
  final List<Order> orders = [];
  final List<String> recentSearches = [];
  String? userName;
  String? userEmail;
  String address = 'House 12, Road 5, Bashundhara R/A, Dhaka 1229';
  String? couponCode;
  bool onboarded = false;
  bool ready = false;
  String? loadError;

  SharedPreferences? _prefs;

  dynamic _decodeSaved(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    loadError = null;
    ready = false;
    notifyListeners();
    try {
      final raw = await rootBundle.loadString('assets/data/products.json');
      products = (jsonDecode(raw) as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      _buildCatalogueViews();
    } catch (_) {
      loadError = 'Your catalogue could not be loaded. Please try again.';
      notifyListeners();
      return;
    }
    try {
      _prefs = await SharedPreferences.getInstance();
      final p = _prefs!;
      onboarded = p.getBool('onboarded') ?? false;
      liveNebula.value = p.getBool('liveBackground') ?? false;
      userName = p.getString('userName');
      if (userName?.trim().isEmpty ?? false) userName = null;
      userEmail = p.getString('userEmail');
      _token = p.getString('authToken');
      api?.token = _token;
      address = p.getString('address') ?? address;
      final savedCoupon = p.getString('couponCode');
      couponCode = savedCoupon == Brand.couponCode ? savedCoupon : null;
      wishlist.clear();
      for (final id in p.getStringList('wishlist') ?? <String>[]) {
        final parsed = int.tryParse(id);
        if (parsed != null && byId(parsed) != null) wishlist.add(parsed);
      }
      recentSearches
        ..clear()
        ..addAll((p.getStringList('recent') ?? []).take(8));
      _cart.clear();
      final cart = _decodeSaved(p.getString('cart'));
      if (cart is Map<String, dynamic>) {
        cart.forEach((k, v) {
          final id = int.tryParse(k);
          final prod = id == null ? null : byId(id);
          if (prod != null && v is int && v > 0) {
            _cart[prod.id] = CartItem(prod, v.clamp(1, 99));
          }
        });
      }
      final o = _decodeSaved(p.getString('orders'));
      if (o is List) {
        orders.clear();
        for (final entry in o) {
          try {
            orders.add(Order.fromJson(entry as Map<String, dynamic>));
          } catch (_) {
            /* A damaged order should not hide the remaining history. */
          }
        }
      }
    } catch (_) {
      // Storage unavailable (e.g. private browsing) — run in-memory.
    }
    ready = true;
    notifyListeners();
    // The app is usable now; catch up with the server in the background.
    if (api != null) unawaited(refresh());
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setBool('onboarded', onboarded);
    p.setBool('liveBackground', liveNebula.value);
    if (userName != null) p.setString('userName', userName!);
    if (userEmail != null) p.setString('userEmail', userEmail!);
    if (_token == null) {
      p.remove('authToken');
    } else {
      p.setString('authToken', _token!);
    }
    p.setString('address', address);
    if (couponCode == null) {
      p.remove('couponCode');
    } else {
      p.setString('couponCode', couponCode!);
    }
    p.setStringList('wishlist', wishlist.map((e) => '$e').toList());
    p.setStringList('recent', recentSearches);
    p.setString(
      'cart',
      jsonEncode({for (final c in _cart.values) '${c.product.id}': c.qty}),
    );
    p.setString('orders', jsonEncode(orders.map((o) => o.toJson()).toList()));
  }

  /// Saves and redraws. [sync]: the cart, voucher or wishlist changed, so
  /// send them to the server shortly.
  void _changed({bool sync = false}) {
    _save();
    notifyListeners();
    if (sync) _schedulePush();
  }

  // ---- Server sync ----

  /// Fetches the latest catalogue and, when signed in, the account's
  /// profile, cart, wishlist and orders, merged with what is on the device.
  /// Safe to call any time; calls that overlap share one run.
  Future<void> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    final api = this.api;
    if (api == null) return;
    try {
      await _refreshCatalogue(api);
      if (_token != null) await _pullAccount(api);
      online = true;
    } on ApiException catch (e) {
      _failed(e);
    }
    notifyListeners();
  }

  Future<void> _refreshCatalogue(ShopApi api) async {
    final fresh = await api.products();
    if (fresh.isEmpty) return;
    products = fresh;
    _buildCatalogueViews();
    // Point the cart at the new product objects (new price and stock);
    // drop anything no longer sold.
    final old = Map.of(_cart);
    _cart.clear();
    old.forEach((id, c) {
      final p = byId(id);
      if (p != null) _cart[id] = CartItem(p, c.qty);
    });
    wishlist.removeWhere((id) => byId(id) == null);
  }

  /// Merges the server account into the device: profile from the server,
  /// cart and wishlist joined (nothing added on either side is lost), all
  /// orders. Then sends the merged cart and wishlist back.
  Future<void> _pullAccount(ShopApi api) async {
    final me = await api.me();
    userName = me.name;
    userEmail = me.email;
    if (me.address.isNotEmpty) {
      address = me.address;
    } else {
      try {
        await api.updateMe(address: address);
      } on ApiException catch (e) {
        if (e.offline) rethrow; // A refused address just stays local.
      }
    }

    final remote = await api.cart();
    remote.items.forEach((id, qty) {
      final p = byId(id);
      if (p == null) return;
      final mine = _cart[id];
      if (mine == null) {
        _cart[id] = CartItem(p, qty.clamp(1, 99));
      } else if (qty > mine.qty) {
        mine.qty = qty.clamp(1, 99);
      }
    });
    couponCode ??= remote.coupon == Brand.couponCode ? remote.coupon : null;

    wishlist.addAll((await api.wishlist()).where((id) => byId(id) != null));

    final fromServer = await api.orders();
    final serverIds = {for (final o in fromServer) o.id};
    final merged = [
      ...fromServer,
      ...orders.where((o) => !serverIds.contains(o.id)),
    ]..sort((a, b) => b.date.compareTo(a.date));
    orders
      ..clear()
      ..addAll(merged);
    _save();
    await _push(api);
  }

  void _schedulePush() {
    if (api == null || _token == null) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(milliseconds: 350), () {
      _pushTimer = null;
      _pushing = _pushQuietly();
    });
  }

  Future<void> _pushQuietly() async {
    final api = this.api;
    if (api == null || _token == null) return;
    try {
      await _push(api);
      online = true;
    } on ApiException catch (e) {
      _failed(e);
    }
    notifyListeners();
  }

  Future<void> _push(ShopApi api) async {
    await api.putCart({
      for (final c in _cart.values) c.product.id: c.qty,
    }, couponCode);
    await api.putWishlist(wishlist);
  }

  /// Sends any change still waiting to the server, then returns.
  Future<void> flush() async {
    if (_pushTimer != null) {
      _pushTimer!.cancel();
      _pushTimer = null;
      _pushing = _pushQuietly();
    }
    await _pushing;
  }

  /// Remembers that the server could not help. A refused token means the
  /// session is over: keep the shopper's things, forget the token.
  void _failed(ApiException e) {
    online = !e.offline;
    if (e.status == 401 && _token != null) {
      _token = null;
      api?.token = null;
      _save();
    }
  }

  bool _disposed = false;

  // A server reply can arrive after the screen that owned this is gone.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pushTimer?.cancel();
    super.dispose();
  }

  Product? byId(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // Catalogue views are fixed once loaded, so build them once in load()
  // instead of on every rebuild (the home screen rebuilds on each cart
  // change). Building them in load() also means a retry after a failed
  // load gets fresh lists rather than empty ones cached too early.
  final Map<String, List<Product>> _byCategory = {};
  List<Product> inCategory(String c) => _byCategory[c] ?? const [];

  List<Product> flashSale = [];
  List<Product> topRated = [];

  /// "Just for you" — interleave categories so the feed feels varied.
  List<Product> forYou = [];

  void _buildCatalogueViews() {
    _byCategory.clear();
    for (final p in products) {
      _byCategory.putIfAbsent(p.category, () => []).add(p);
    }
    flashSale = ([
      ...products,
    ]..sort((a, b) => b.discount.compareTo(a.discount))).take(12).toList();
    // A 5.0 from 2 buyers shouldn't beat a 4.8 from 900, so rank by a
    // weighted rating that pulls small samples toward an average 4.0.
    double score(Product p) =>
        (p.rating * p.ratings + 4.0 * 20) / (p.ratings + 20);
    topRated = ([
      ...products,
    ]..sort((a, b) => score(b).compareTo(score(a)))).take(10).toList();
    forYou = _interleave();
  }

  List<Product> _interleave() {
    final byCat = <String, List<Product>>{};
    for (final p in products) {
      byCat.putIfAbsent(p.category, () => []).add(p);
    }
    final out = <Product>[];
    var i = 0;
    while (out.length < products.length) {
      for (final l in byCat.values) {
        if (i < l.length) out.add(l[i]);
      }
      i++;
    }
    return out;
  }

  List<Product> search(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return [];
    return products
        .where(
          (p) =>
              p.title.toLowerCase().contains(s) ||
              p.brand.toLowerCase().contains(s) ||
              p.category.replaceAll('-', ' ').contains(s) ||
              categoryOf(p.category).bangla.contains(s),
        )
        .toList();
  }

  void addRecentSearch(String q) {
    final s = q.trim();
    if (s.isEmpty) return;
    recentSearches
      ..removeWhere((item) => item.toLowerCase() == s.toLowerCase())
      ..insert(0, s);
    if (recentSearches.length > 8) recentSearches.removeLast();
    _changed();
  }

  void clearRecent() {
    recentSearches.clear();
    _changed();
  }

  // ---- Cart ----
  List<CartItem> get cart => _cart.values.toList();
  int get cartCount => _cart.values.fold(0, (a, c) => a + c.qty);
  int get subtotal =>
      _cart.values.fold(0, (a, c) => a + c.product.price * c.qty);
  int get savings => _cart.values.fold(
    0,
    (a, c) => a + (c.product.originalPrice - c.product.price) * c.qty,
  );
  int get delivery => _cart.isEmpty || subtotal >= Brand.freeDeliveryOver
      ? 0
      : Brand.deliveryFee;
  int get couponDiscount => couponCode == Brand.couponCode
      ? (subtotal * Brand.couponPercent / 100).round().clamp(
          0,
          Brand.couponMaxDiscount,
        )
      : 0;
  int get total => subtotal + delivery - couponDiscount;
  int qtyOf(int id) => _cart[id]?.qty ?? 0;

  void addToCart(Product p, [int qty = 1]) {
    if (qty <= 0) return;
    final c = _cart[p.id];
    if (c == null) {
      _cart[p.id] = CartItem(p, qty.clamp(1, 99));
    } else {
      c.qty = (c.qty + qty).clamp(1, 99);
    }
    _changed(sync: true);
  }

  void setQty(Product p, int qty) {
    if (qty <= 0) {
      _cart.remove(p.id);
    } else {
      _cart[p.id]?.qty = qty.clamp(1, 99);
    }
    _changed(sync: true);
  }

  void removeFromCart(Product p) {
    _cart.remove(p.id);
    _changed(sync: true);
  }

  bool applyCoupon(String code) {
    if (code.trim().toUpperCase() == Brand.couponCode) {
      couponCode = Brand.couponCode;
      _changed(sync: true);
      return true;
    }
    return false;
  }

  // ---- Wishlist ----
  bool isWished(int id) => wishlist.contains(id);
  void toggleWish(Product p) {
    if (!wishlist.remove(p.id)) wishlist.add(p.id);
    _changed(sync: true);
  }

  List<Product> get wishProducts =>
      wishlist.map(byId).whereType<Product>().toList();

  // ---- Account ----
  void setLiveBackground(bool on) {
    liveNebula.value = on;
    _changed();
  }

  void finishOnboarding() {
    onboarded = true;
    _changed();
  }

  /// Signs in on this device only (guest, or no server).
  void signIn(String name, String email) {
    userName = name.trim().isEmpty ? 'Shopper' : name.trim();
    userEmail = email.trim();
    _changed();
  }

  /// Signs in to a server account. Wrong details throw an [ApiException]
  /// with a message to show. If the server can't be reached, signs in on
  /// this device with [offlineName] and returns [AuthResult.offline].
  Future<AuthResult> login(
    String email,
    String password, {
    required String offlineName,
  }) => _authenticate(
    (api) => api.login(email, password),
    offlineName: offlineName,
    email: email,
  );

  /// Creates a server account (see [login] for errors and offline).
  Future<AuthResult> register(String name, String email, String password) =>
      _authenticate(
        (api) => api.register(name, email, password),
        offlineName: name,
        email: email,
      );

  Future<AuthResult> _authenticate(
    Future<ApiSession> Function(ShopApi api) call, {
    required String offlineName,
    required String email,
  }) async {
    final api = this.api;
    if (api == null) {
      signIn(offlineName, email);
      return AuthResult.offline;
    }
    final ApiSession session;
    try {
      session = await call(api);
    } on ApiException catch (e) {
      if (!e.offline) rethrow;
      online = false;
      signIn(offlineName, email);
      return AuthResult.offline;
    }
    _token = session.token;
    api.token = session.token;
    userName = session.user.name;
    userEmail = session.user.email;
    online = true;
    _changed();
    try {
      await _pullAccount(api);
    } on ApiException catch (e) {
      _failed(e);
    }
    notifyListeners();
    return AuthResult.online;
  }

  /// Signs out. For a server account the cart, wishlist and orders belong
  /// to the account, so they leave this device too (they come back on the
  /// next sign-in).
  void signOut() {
    final token = _token;
    if (token != null) {
      _pushTimer?.cancel();
      _pushTimer = null;
      unawaited(api?.logout(token).then((_) {}, onError: (Object _) {}));
      _token = null;
      api?.token = null;
      _cart.clear();
      wishlist.clear();
      orders.clear();
      couponCode = null;
      _save();
    }
    userName = null;
    userEmail = null;
    _prefs?.remove('userName');
    _prefs?.remove('userEmail');
    notifyListeners();
  }

  void setAddress(String a) {
    address = a;
    _changed();
    final api = this.api;
    if (api != null && _token != null) {
      unawaited(
        api
            .updateMe(address: a)
            .then(
              (_) => online = true,
              onError: (Object e) {
                if (e is ApiException) _failed(e);
              },
            ),
      );
    }
  }

  /// Places the order. With a server account the server checks stock and
  /// works out the total; a refusal (e.g. sold out) throws an
  /// [ApiException] and leaves the cart as it is. Guests, and everyone
  /// while the server is unreachable, get the order saved on the device.
  Future<Order> checkout(String payment) async {
    if (_cart.isEmpty) throw StateError('Your cart is empty');
    final api = this.api;
    if (api == null || _token == null) return placeOrder(payment);
    _pushTimer?.cancel();
    _pushTimer = null;
    final Order order;
    try {
      order = await api.placeOrder(
        items: {for (final c in _cart.values) c.product.id: c.qty},
        coupon: couponCode,
        payment: payment,
        address: address,
      );
    } on ApiException catch (e) {
      _failed(e);
      notifyListeners();
      if (e.offline) return placeOrder(payment);
      rethrow;
    }
    online = true;
    orders.insert(0, order);
    _cart.clear();
    couponCode = null;
    _changed();
    // Stock just changed on the server.
    unawaited(
      _refreshCatalogue(api)
          .then((_) => notifyListeners(), onError: (Object _) {}),
    );
    return order;
  }

  /// Saves the order on this device only.
  Order placeOrder(String payment) {
    if (_cart.isEmpty) throw StateError('Your cart is empty');
    final now = DateTime.now();
    final order = Order(
      id: '${Brand.orderPrefix}${now.millisecondsSinceEpoch.toString().substring(5)}',
      date: now,
      total: total,
      payment: payment,
      address: address,
      lines: [
        for (final c in _cart.values)
          (
            productId: c.product.id,
            title: c.product.title,
            thumbnail: c.product.thumbnail,
            price: c.product.price,
            qty: c.qty,
          ),
      ],
    );
    orders.insert(0, order);
    _cart.clear();
    couponCode = null;
    _changed();
    return order;
  }
}

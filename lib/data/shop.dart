import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/brand.dart';
import '../widgets/space_background.dart';
import 'models.dart';

String taka(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  // South-Asian grouping: 12,34,567
  if (s.length <= 3) return '৳$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  buf.write(parts.join(','));
  return '৳$buf,$last3';
}

/// All app state: catalogue, cart, wishlist, orders and account.
/// Persisted locally so the app keeps its state across launches.
class Shop extends ChangeNotifier {
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
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setBool('onboarded', onboarded);
    p.setBool('liveBackground', liveNebula.value);
    if (userName != null) p.setString('userName', userName!);
    if (userEmail != null) p.setString('userEmail', userEmail!);
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

  void _changed() {
    _save();
    notifyListeners();
  }

  Product? byId(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // Catalogue views are fixed once loaded, so compute them once instead of
  // on every rebuild (the home screen rebuilds on each cart change).
  final Map<String, List<Product>> _byCategory = {};
  List<Product> inCategory(String c) => _byCategory.putIfAbsent(
    c,
    () => products.where((p) => p.category == c).toList(),
  );

  late final List<Product> flashSale = ([
    ...products,
  ]..sort((a, b) => b.discount.compareTo(a.discount))).take(12).toList();

  late final List<Product> topRated = ([
    ...products,
  ]..sort((a, b) => b.rating.compareTo(a.rating))).take(10).toList();

  /// "Just for you" — interleave categories so the feed feels varied.
  late final List<Product> forYou = _interleave();

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
    _changed();
  }

  void setQty(Product p, int qty) {
    if (qty <= 0) {
      _cart.remove(p.id);
    } else {
      _cart[p.id]?.qty = qty.clamp(1, 99);
    }
    _changed();
  }

  void removeFromCart(Product p) {
    _cart.remove(p.id);
    _changed();
  }

  bool applyCoupon(String code) {
    if (code.trim().toUpperCase() == Brand.couponCode) {
      couponCode = Brand.couponCode;
      _changed();
      return true;
    }
    return false;
  }

  // ---- Wishlist ----
  bool isWished(int id) => wishlist.contains(id);
  void toggleWish(Product p) {
    if (!wishlist.remove(p.id)) wishlist.add(p.id);
    _changed();
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

  void signIn(String name, String email) {
    userName = name.trim().isEmpty ? 'Shopper' : name.trim();
    userEmail = email.trim();
    _changed();
  }

  void signOut() {
    userName = null;
    userEmail = null;
    _prefs?.remove('userName');
    _prefs?.remove('userEmail');
    notifyListeners();
  }

  void setAddress(String a) {
    address = a;
    _changed();
  }

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

/// "1 item", "3 items".
String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

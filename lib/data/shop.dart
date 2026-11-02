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

  SharedPreferences? _prefs;

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/products.json');
    products = (jsonDecode(raw) as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    try {
      _prefs = await SharedPreferences.getInstance();
      final p = _prefs!;
      onboarded = p.getBool('onboarded') ?? false;
      liveNebula.value = p.getBool('liveBackground') ?? true;
      userName = p.getString('userName');
      userEmail = p.getString('userEmail');
      address = p.getString('address') ?? address;
      wishlist.addAll((p.getStringList('wishlist') ?? []).map(int.parse));
      recentSearches.addAll(p.getStringList('recent') ?? []);
      final cart = p.getString('cart');
      if (cart != null) {
        (jsonDecode(cart) as Map<String, dynamic>).forEach((k, v) {
          final prod = byId(int.parse(k));
          if (prod != null) _cart[prod.id] = CartItem(prod, v as int);
        });
      }
      final o = p.getString('orders');
      if (o != null) {
        orders.addAll(
          (jsonDecode(o) as List).map(
            (e) => Order.fromJson(e as Map<String, dynamic>),
          ),
        );
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
      ..remove(s)
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
    final c = _cart[p.id];
    if (c == null) {
      _cart[p.id] = CartItem(p, qty);
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
      notifyListeners();
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
    userName = name;
    userEmail = email;
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

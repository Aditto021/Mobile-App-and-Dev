/// MODULE: Store — everything the server remembers: accounts, sign-in
/// sessions, carts, wishlists, orders and units sold. Kept in memory and
/// written to one JSON file after each change (write to a temp file, then
/// rename, so a crash never leaves half a file).
///
/// Contains: User, CartData, Store.
library;

import 'dart:convert';
import 'dart:io';

class User {
  final int id;
  String name;

  /// Email (lower case) or phone number (01XXXXXXXXX) used to sign in.
  final String login;
  final String salt;
  final String hash;
  String address;
  final DateTime created;

  User({
    required this.id,
    required this.name,
    required this.login,
    required this.salt,
    required this.hash,
    required this.address,
    required this.created,
  });

  /// What the API sends back — never the password hash.
  Map<String, dynamic> toPublicJson() => {
    'id': id,
    'name': name,
    'email': login,
    'address': address,
    'created': created.toIso8601String(),
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'login': login,
    'salt': salt,
    'hash': hash,
    'address': address,
    'created': created.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as int,
    name: j['name'] as String,
    login: j['login'] as String,
    salt: j['salt'] as String,
    hash: j['hash'] as String,
    address: j['address'] as String? ?? '',
    created: DateTime.parse(j['created'] as String),
  );
}

class CartData {
  /// productId → quantity, in the order items were added.
  final Map<int, int> items;
  String? coupon;
  CartData([Map<int, int>? items, this.coupon]) : items = items ?? {};

  Map<String, dynamic> toJson() => {
    'items': {for (final e in items.entries) '${e.key}': e.value},
    'coupon': coupon,
  };

  factory CartData.fromJson(Map<String, dynamic> j) => CartData({
    for (final e in (j['items'] as Map).entries)
      int.parse(e.key as String): e.value as int,
  }, j['coupon'] as String?);
}

class Store {
  final String? path;
  Store._(this.path);

  /// Accounts by login.
  final users = <String, User>{};

  /// Sessions by the SHA-256 of the token (the token itself is never kept).
  final sessions = <String, ({int userId, DateTime expires})>{};

  final carts = <int, CartData>{};
  final wishlists = <int, List<int>>{};

  /// Every order, oldest first. Each holds its owner's `userId`.
  final orders = <Map<String, dynamic>>[];

  /// Units sold per product, taken off the catalogue stock.
  final sold = <int, int>{};

  int _nextUserId = 1;
  int newUserId() => _nextUserId++;

  User? userById(int id) {
    for (final u in users.values) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Opens the store at [path], or an in-memory one when [path] is null.
  static Future<Store> open([String? path]) async {
    final store = Store._(path);
    if (path == null) return store;
    final file = File(path);
    if (!await file.exists()) return store;
    final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    store._nextUserId = j['nextUserId'] as int? ?? 1;
    for (final u in (j['users'] as List? ?? const [])) {
      final user = User.fromJson(Map<String, dynamic>.from(u as Map));
      store.users[user.login] = user;
    }
    final now = DateTime.now();
    (j['sessions'] as Map? ?? const {}).forEach((k, v) {
      final expires = DateTime.parse(v['expires'] as String);
      if (expires.isAfter(now)) {
        store.sessions[k as String] = (
          userId: v['userId'] as int,
          expires: expires,
        );
      }
    });
    (j['carts'] as Map? ?? const {}).forEach((k, v) {
      store.carts[int.parse(k as String)] = CartData.fromJson(
        Map<String, dynamic>.from(v as Map),
      );
    });
    (j['wishlists'] as Map? ?? const {}).forEach((k, v) {
      store.wishlists[int.parse(k as String)] = (v as List).cast<int>();
    });
    for (final o in (j['orders'] as List? ?? const [])) {
      store.orders.add(Map<String, dynamic>.from(o as Map));
    }
    (j['sold'] as Map? ?? const {}).forEach((k, v) {
      store.sold[int.parse(k as String)] = v as int;
    });
    return store;
  }

  Map<String, dynamic> toJson() => {
    'nextUserId': _nextUserId,
    'users': [for (final u in users.values) u.toJson()],
    'sessions': {
      for (final e in sessions.entries)
        e.key: {
          'userId': e.value.userId,
          'expires': e.value.expires.toIso8601String(),
        },
    },
    'carts': {for (final e in carts.entries) '${e.key}': e.value.toJson()},
    'wishlists': {for (final e in wishlists.entries) '${e.key}': e.value},
    'orders': orders,
    'sold': {for (final e in sold.entries) '${e.key}': e.value},
  };

  Future<void> _writing = Future.value();

  /// Writes the store to disk. Writes run one after another, each with the
  /// state at the moment it was asked for.
  Future<void> save() {
    final target = path;
    if (target == null) return Future.value();
    final snapshot = const JsonEncoder.withIndent(' ').convert(toJson());
    return _writing = _writing.then((_) async {
      try {
        final tmp = File('$target.tmp');
        await tmp.parent.create(recursive: true);
        await tmp.writeAsString(snapshot, flush: true);
        await tmp.rename(target);
      } catch (e) {
        stderr.writeln('Could not save $target: $e');
      }
    });
  }
}

/// MODULE: Catalogue — the product list the server sells, read from the
/// app's assets/data/products.json. Products are read-only here; stock that
/// changes with orders is tracked by the Store.
///
/// Contains: Catalogue.
library;

import 'dart:convert';
import 'dart:io';

class Catalogue {
  final List<Map<String, dynamic>> items;
  final Map<int, Map<String, dynamic>> _byId;

  /// Category ids in the order they first appear.
  final List<String> categories;

  Catalogue(this.items)
    : _byId = {for (final p in items) p['id'] as int: p},
      categories = items.map((p) => p['category'] as String).toSet().toList();

  factory Catalogue.parse(String raw) {
    final list = jsonDecode(raw) as List;
    return Catalogue([
      for (final p in list) Map<String, dynamic>.from(p as Map),
    ]);
  }

  static Future<Catalogue> load(String path) async =>
      Catalogue.parse(await File(path).readAsString());

  Map<String, dynamic>? byId(int id) => _byId[id];

  static int priceOf(Map<String, dynamic> p) => (p['price'] as num).toInt();

  /// Price before the discount, rounded the same way the app does.
  static int originalPriceOf(Map<String, dynamic> p) {
    final price = priceOf(p);
    final discount = (p['discount'] as num).toInt();
    return discount <= 0 ? price : (price * 100 / (100 - discount)).round();
  }
}

/// MODULE: Product model — one catalogue item loaded from
/// assets/data/products.json (prices in Taka, discount in percent).
library;

import 'review.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final int price; // in ৳, after discount
  final int discount; // percent
  final double rating;
  final int stock;
  final String brand;
  final String thumbnail;
  final List<String> images;
  final List<Review> reviews;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discount,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.thumbnail,
    required this.images,
    required this.reviews,
  });

  int get originalPrice =>
      discount <= 0 ? price : (price * 100 / (100 - discount)).round();

  /// Deterministic "sold" count so the number is stable between launches.
  int get sold => 120 + (id * 7919) % 4800;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as int,
    title: j['title'] as String,
    description: j['description'] as String,
    category: j['category'] as String,
    price: (j['price'] as num).toInt(),
    discount: (j['discount'] as num).toInt(),
    rating: (j['rating'] as num).toDouble(),
    stock: (j['stock'] as num).toInt(),
    brand: j['brand'] as String,
    thumbnail: j['thumbnail'] as String,
    images: (j['images'] as List).cast<String>(),
    reviews: (j['reviews'] as List)
        .map((r) => Review.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
}

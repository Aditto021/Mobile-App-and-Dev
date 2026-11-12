/// MODULE: Product model — one catalogue item loaded from
/// assets/data/products.json (built by tool/build_catalogue.mjs from real
/// Bangladeshi market listings): prices in Taka, discount in percent, with
/// the seller, sales and rating figures.
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

  /// Written customer reviews, if any.
  final List<Review> reviews;

  /// Total number of ratings (can be more than [reviews] holds).
  final int reviewCount;

  /// Units sold, or 0 when there is no figure.
  final int soldCount;

  /// The shop selling it, and where it ships from.
  final String seller;
  final String location;

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
    this.reviewCount = 0,
    this.soldCount = 0,
    this.seller = '',
    this.location = '',
  });

  int get originalPrice =>
      discount <= 0 ? price : (price * 100 / (100 - discount)).round();

  /// Units sold: the real figure when there is one, otherwise a stable
  /// estimate so the number doesn't change between launches.
  int get sold => soldCount > 0 ? soldCount : 20 + (id * 7919) % 480;

  /// Ratings to show next to the stars.
  int get ratings =>
      reviewCount > reviews.length ? reviewCount : reviews.length;

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
    reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
    soldCount: (j['sold'] as num?)?.toInt() ?? 0,
    seller: j['seller'] as String? ?? '',
    location: j['location'] as String? ?? '',
  );
}

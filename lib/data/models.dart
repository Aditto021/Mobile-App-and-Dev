import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';

class Review {
  final int rating;
  final String comment;
  final String name;
  const Review(this.rating, this.comment, this.name);

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    (j['rating'] as num).toInt(),
    j['comment'] as String,
    j['name'] as String,
  );
}

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

class CategoryInfo {
  final String id;
  final String name;
  final String bangla;
  final IconData icon;
  final Color color;
  const CategoryInfo(this.id, this.name, this.bangla, this.icon, this.color);
}

const categories = <CategoryInfo>[
  CategoryInfo(
    'smartphones',
    'Phones',
    'ফোন',
    Iconsax.mobile,
    AppColors.violetLight,
  ),
  CategoryInfo(
    'laptops',
    'Laptops',
    'ল্যাপটপ',
    Iconsax.monitor,
    AppColors.cyan,
  ),
  CategoryInfo(
    'mobile-accessories',
    'Gadgets',
    'গ্যাজেট',
    Iconsax.headphone,
    AppColors.magenta,
  ),
  CategoryInfo(
    'tablets',
    'Tablets',
    'ট্যাবলেট',
    Iconsax.monitor_mobbile,
    AppColors.indigo,
  ),
  CategoryInfo(
    'mens-watches',
    'Watches',
    'ঘড়ি',
    Iconsax.watch,
    AppColors.gold,
  ),
  CategoryInfo(
    'fragrances',
    'Fragrance',
    'সুগন্ধি',
    Iconsax.magic_star,
    AppColors.rose,
  ),
  CategoryInfo(
    'beauty',
    'Beauty',
    'রূপচর্চা',
    Iconsax.brush,
    AppColors.magenta,
  ),
  CategoryInfo(
    'skin-care',
    'Skin Care',
    'ত্বকের যত্ন',
    Iconsax.lovely,
    AppColors.mint,
  ),
  CategoryInfo('mens-shirts', 'Men', 'পুরুষ', Iconsax.man, AppColors.cyan),
  CategoryInfo(
    'womens-dresses',
    'Women',
    'নারী',
    Iconsax.woman,
    AppColors.rose,
  ),
  CategoryInfo(
    'womens-bags',
    'Bags',
    'ব্যাগ',
    Iconsax.bag_2,
    AppColors.violetLight,
  ),
  CategoryInfo(
    'womens-jewellery',
    'Jewellery',
    'গহনা',
    Iconsax.crown,
    AppColors.gold,
  ),
  CategoryInfo('mens-shoes', 'Shoes', 'জুতা', Iconsax.ruler, AppColors.indigo),
  CategoryInfo('womens-shoes', 'Heels', 'হিল', Iconsax.star, AppColors.magenta),
  CategoryInfo(
    'womens-watches',
    'Her Watch',
    'নারীর ঘড়ি',
    Iconsax.watch_status,
    AppColors.rose,
  ),
  CategoryInfo(
    'sunglasses',
    'Sunglasses',
    'সানগ্লাস',
    Iconsax.glass,
    AppColors.cyan,
  ),
  CategoryInfo('tops', 'Tops', 'টপস', Iconsax.woman, AppColors.violetLight),
  CategoryInfo(
    'groceries',
    'Groceries',
    'মুদি',
    Iconsax.shopping_cart,
    AppColors.mint,
  ),
  CategoryInfo(
    'kitchen-accessories',
    'Kitchen',
    'রান্নাঘর',
    Iconsax.coffee,
    AppColors.gold,
  ),
  CategoryInfo(
    'furniture',
    'Furniture',
    'ফার্নিচার',
    Iconsax.lamp,
    AppColors.indigo,
  ),
  CategoryInfo(
    'home-decoration',
    'Decor',
    'সাজসজ্জা',
    Iconsax.home_2,
    AppColors.magenta,
  ),
  CategoryInfo(
    'sports-accessories',
    'Sports',
    'খেলাধুলা',
    Iconsax.medal,
    AppColors.mint,
  ),
  CategoryInfo('motorcycle', 'Bikes', 'বাইক', Iconsax.flash, AppColors.rose),
  CategoryInfo('vehicle', 'Cars', 'গাড়ি', Iconsax.car, AppColors.cyan),
];

CategoryInfo categoryOf(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.first);

class CartItem {
  final Product product;
  int qty;
  CartItem(this.product, this.qty);
}

enum OrderStatus { placed, packed, shipped, delivered }

class Order {
  final String id;
  final DateTime date;
  final List<
    ({int productId, String title, String thumbnail, int price, int qty})
  >
  lines;
  final int total;
  final String payment;
  final String address;
  const Order({
    required this.id,
    required this.date,
    required this.lines,
    required this.total,
    required this.payment,
    required this.address,
  });

  /// Orders advance one step per elapsed minute — simulates live tracking.
  OrderStatus get status {
    final mins = DateTime.now().difference(date).inMinutes;
    return OrderStatus.values[mins.clamp(0, OrderStatus.values.length - 1)];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'total': total,
    'payment': payment,
    'address': address,
    'lines': [
      for (final l in lines)
        {
          'productId': l.productId,
          'title': l.title,
          'thumbnail': l.thumbnail,
          'price': l.price,
          'qty': l.qty,
        },
    ],
  };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'] as String,
    date: DateTime.parse(j['date'] as String),
    total: j['total'] as int,
    payment: j['payment'] as String,
    address: j['address'] as String,
    lines: [
      for (final l in (j['lines'] as List).cast<Map<String, dynamic>>())
        (
          productId: l['productId'] as int,
          title: l['title'] as String,
          thumbnail: l['thumbnail'] as String,
          price: l['price'] as int,
          qty: l['qty'] as int,
        ),
    ],
  );
}

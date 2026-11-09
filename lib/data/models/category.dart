/// MODULE: Category model — the fixed list of shop categories
/// (English + Bangla name, icon and accent colour).
library;

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_theme.dart';

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

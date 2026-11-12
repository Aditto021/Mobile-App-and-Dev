/// MODULE: Category model — the fixed list of shop categories
/// (English + Bangla name, icon and accent colour). The products in each
/// come from assets/data/products.json.
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
    'smartwatches',
    'Smartwatch',
    'স্মার্টওয়াচ',
    Iconsax.watch_status,
    AppColors.cyan,
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
  CategoryInfo('mens-fashion', 'Men', 'পুরুষ', Iconsax.man, AppColors.cyan),
  CategoryInfo(
    'womens-fashion',
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
];

CategoryInfo categoryOf(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.first);

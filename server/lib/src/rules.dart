/// MODULE: Shop rules — the business rules the server enforces (same values
/// as the app's Brand config) and the price quote for a cart.
///
/// Contains: Rules, Quote, quoteFor.
library;

abstract final class Rules {
  static const couponCode = 'FERIWALA10';
  static const couponPercent = 10;
  static const couponMaxDiscount = 1500; // ৳
  static const freeDeliveryOver = 2000; // ৳
  static const deliveryFee = 60; // ৳
  static const orderPrefix = 'FW';
  static const maxQty = 99;

  /// Payment methods the checkout offers.
  static const payments = [
    'bKash',
    'Nagad',
    'Credit / Debit card',
    'Cash on delivery',
  ];

  static const sessionLife = Duration(days: 30);
  static const maxLoginFailures = 5;
  static const lockout = Duration(minutes: 1);

  /// True when [code] is the shop voucher (spaces and case ignored).
  static bool isCoupon(String? code) =>
      code != null && code.trim().toUpperCase() == couponCode;
}

/// What a cart costs, in ৳.
class Quote {
  final int items;
  final int subtotal;
  final int savings;
  final int delivery;
  final int discount;
  const Quote({
    required this.items,
    required this.subtotal,
    required this.savings,
    required this.delivery,
    required this.discount,
  });

  int get total => subtotal + delivery - discount;

  Map<String, dynamic> toJson() => {
    'items': items,
    'subtotal': subtotal,
    'savings': savings,
    'delivery': delivery,
    'discount': discount,
    'total': total,
  };
}

/// Prices a cart. [lines] holds (price, originalPrice, qty) per product.
///
/// Delivery is free on an empty cart or from ৳2,000; otherwise ৳60.
/// The voucher takes 10% off the subtotal, at most ৳1,500.
Quote quoteFor(
  Iterable<({int price, int originalPrice, int qty})> lines, {
  String? coupon,
}) {
  var items = 0, subtotal = 0, savings = 0;
  for (final l in lines) {
    items += l.qty;
    subtotal += l.price * l.qty;
    savings += (l.originalPrice - l.price) * l.qty;
  }
  final delivery = items == 0 || subtotal >= Rules.freeDeliveryOver
      ? 0
      : Rules.deliveryFee;
  final discount = Rules.isCoupon(coupon)
      ? (subtotal * Rules.couponPercent / 100).round().clamp(
          0,
          Rules.couponMaxDiscount,
        )
      : 0;
  return Quote(
    items: items,
    subtotal: subtotal,
    savings: savings,
    delivery: delivery,
    discount: discount,
  );
}

/// MODULE: Order model — a placed order, its lines and its simulated
/// delivery status. Saved to the device as JSON.
library;

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

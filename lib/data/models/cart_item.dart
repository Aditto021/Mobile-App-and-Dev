/// MODULE: Cart item model — a product and its quantity in the cart.
library;

import 'product.dart';

class CartItem {
  final Product product;
  int qty;
  CartItem(this.product, this.qty);
}

/// MODULE: Review model — one customer review on a product.
library;

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

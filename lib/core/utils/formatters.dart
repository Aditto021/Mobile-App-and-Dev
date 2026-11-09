/// MODULE: Formatters — turn numbers into display text.
library;

/// Price in Taka with South-Asian digit grouping: 1234567 → ৳12,34,567.
String taka(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  if (s.length <= 3) return '৳$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  buf.write(parts.join(','));
  return '৳$buf,$last3';
}

/// "1 item", "3 items".
String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

// ignore_for_file: avoid_print
// Copies the brand values from lib/config/brand.dart into the platform
// files Dart code can't reach. Run from the app folder:
//   dart run tool/apply_brand.dart
import 'dart:io';

String read(String key, String src) {
  final m = RegExp("static const $key = '([^']*)';").firstMatch(src);
  if (m == null) throw 'Brand.$key not found in lib/config/brand.dart';
  return m.group(1)!;
}

void patch(String path, List<(RegExp, String)> rules) {
  final f = File(path);
  if (!f.existsSync()) return;
  var s = f.readAsStringSync();
  for (final (re, rep) in rules) {
    s = s.replaceAllMapped(re, (m) {
      final capture = m.groupCount > 0 ? m.group(1) ?? '' : '';
      return rep.replaceAll(r'$1', capture);
    });
  }
  f.writeAsStringSync(s);
  print('updated $path');
}

void main() {
  final src = File('lib/config/brand.dart').readAsStringSync();
  final name = read('appName', src);
  final desc = read('description', src);

  patch('android/app/src/main/AndroidManifest.xml', [(RegExp(r'android:label="[^"]*"'), 'android:label="$name"')]);
  patch('web/index.html', [
    (RegExp(r'<title>[^<]*</title>'), '<title>$name</title>'),
    (
      RegExp(r'(name="apple-mobile-web-app-title" content=)"[^"]*"'),
      r'$1"'
          '$name"',
    ),
    (
      RegExp(r'(name="description" content=)"[^"]*"'),
      r'$1"'
          '$desc"',
    ),
  ]);
  patch('web/manifest.json', [
    (RegExp(r'"name": "[^"]*"'), '"name": "$name"'),
    (RegExp(r'"short_name": "[^"]*"'), '"short_name": "$name"'),
    (RegExp(r'"description": "[^"]*"'), '"description": "$desc"'),
  ]);
  patch('pubspec.yaml', [(RegExp(r'^description: .*$', multiLine: true), 'description: "$desc"')]);
  print('Brand applied: $name');
}

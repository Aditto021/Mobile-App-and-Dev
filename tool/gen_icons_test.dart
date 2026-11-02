// Renders the in-app BrandMark into launcher-icon and splash PNGs.
//   flutter test tool/gen_icons_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feriwala/widgets/brand.dart';

Future<void> render(String path, double size, {required bool background, double scale = 1}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final inner = size * scale;
  canvas.translate((size - inner) / 2, (size - inner) / 2);
  BrandMarkPainter(0.12, background: background).paint(canvas, Size.square(inner));
  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate brand icons', () async {
    Directory('assets/brand').createSync(recursive: true);
    await render('assets/brand/icon.png', 1024, background: true, scale: 1.0);
    await render('assets/brand/icon_fg.png', 1024, background: false, scale: 0.62);
    await render('assets/brand/splash.png', 1152, background: false, scale: 0.6);
  });
}

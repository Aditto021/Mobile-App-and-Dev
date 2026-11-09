/// MODULE: Display performance service — Asks Android for the phone's highest
/// screen refresh rate (90/120 Hz) so animations stay smooth.
///
/// Contains: DisplayPerformance.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

class DisplayPerformance {
  static Future<void> configure() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      // Preserve native resolution and request the fastest supported mode.
      // Repeat on resume because Android may reset the preference in background.
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (error) {
      debugPrint('Display mode unavailable: $error');
    }
  }
}

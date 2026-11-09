/// MODULE: Entry point — sets up the phone status bar and orientation,
/// creates the app state (Shop) and starts the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/display_performance_service.dart';
import 'data/state/shop_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => DisplayPerformance.configure(),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => Shop()..load(),
      child: const ShopApp(),
    ),
  );
}

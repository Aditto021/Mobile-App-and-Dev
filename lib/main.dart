import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:provider/provider.dart';

import 'config/brand.dart';
import 'data/shop.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/fly_to_cart.dart';
import 'widgets/space_background.dart';

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
  // Many Android phones run apps at 60 Hz unless they ask for more —
  // request the panel's highest refresh rate (90/120/144 Hz).
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    FlutterDisplayMode.setHighRefreshRate().catchError((Object e) => debugPrint('Refresh rate: $e'));
  }
  runApp(ChangeNotifierProvider(create: (_) => Shop()..load(), child: const ShopApp()));
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Brand.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // One nebula, one blur group and one fly-to-cart layer shared by
      // every screen, so transitions feel like moving through one space.
      builder: (context, child) => BackdropGroup(
        child: SpaceBackground(child: FlyToCart(child: child!)),
      ),
      home: const SplashScreen(),
    );
  }
}

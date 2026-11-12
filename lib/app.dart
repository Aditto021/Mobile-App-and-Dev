/// MODULE: App root — the MaterialApp: title, theme, shared background
/// layers, the wide-screen web stage and the first screen (splash).
library;

import 'package:flutter/material.dart';

import 'core/config/brand_config.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'shared/widgets/fly_to_cart.dart';
import 'shared/widgets/space_background.dart';
import 'shared/widgets/web_stage.dart';

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Brand.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      scrollBehavior: AppTheme.scrollBehavior,
      // One nebula, one blur group and one fly-to-cart layer shared by
      // every screen, so transitions feel like moving through one space.
      // WebStage frames the app on wide browser windows.
      builder: (context, child) => BackdropGroup(
        child: SpaceBackground(
          child: WebStage(child: FlyToCart(child: child!)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

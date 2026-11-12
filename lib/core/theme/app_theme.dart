/// MODULE: App theme — Design tokens: colour palette, Poppins/Hind Siliguri
/// text styles, the dark Material theme and the 3D page transition.
///
/// Contains: AppColors, AppTheme, _SwipeEverywhere, _NebulaTransitions, Txt.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colour palette — "violet space glass".
class AppColors {
  static const void0 = Color(0xFF090812);
  static const void1 = Color(0xFF100F1C);
  static const void2 = Color(0xFF1B192B);

  static const violet = Color(0xFF7955C7);
  static const violetLight = Color(0xFFA78BFA);
  static const lavender = Color(0xFFDDD6FE);
  static const magenta = Color(0xFFB16FAD);
  static const indigo = Color(0xFF4F46E5);
  static const cyan = Color(0xFF22D3EE);
  static const champagne = Color(0xFFF3C98B);
  static const coral = Color(0xFFFF7A75);
  static const gold = Color(0xFFFBBF24);
  static const rose = Color(0xFFFB7185);
  static const mint = Color(0xFF34D399);

  static const text = Color(0xFFF5F3FF);
  static const textDim = Color(0xFFCDD0DD);
  static const textFaint = Color(0xFFA9AFC2);

  static Color glassFill = Colors.white.withValues(alpha: 0.055);
  static Color glassFillStrong = Colors.white.withValues(alpha: 0.10);
  static Color glassBorder = const Color(0xFFB6C5FF).withValues(alpha: 0.17);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7052B6), Color(0xFF9670C7)],
  );

  static const auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5663E9),
      Color(0xFF8B56E8),
      Color(0xFFD65CAB),
      Color(0xFFF3C98B),
    ],
  );

  static const textGradient = LinearGradient(
    colors: [Color(0xFFFFF7E9), Color(0xFFDDD6FE)],
  );
}

class AppTheme {
  static const fontFamily = 'Poppins';
  static const fallback = ['HindSiliguri'];

  /// Lets swipeable views (carousels, galleries, shelves) be dragged with a
  /// mouse too, so the web version swipes like the phone app.
  static const scrollBehavior = _SwipeEverywhere();

  /// The "push back" half of the 3D page transition: while a new screen
  /// opens on top, this one sinks back and fades. Every route uses it, even
  /// ones with their own entrance (such as the splash → shell route).
  static Widget recede(
    BuildContext context,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return child;
    }
    final back = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      // Screens are transparent over the nebula, so the one underneath
      // fades as it recedes instead of showing through.
      opacity: Tween<double>(begin: 1, end: 0.12).animate(back),
      child: AnimatedBuilder(
        animation: back,
        child: child,
        builder: (context, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scaleByDouble(1 - back.value * 0.07, 1 - back.value * 0.07, 1, 1),
          child: child,
        ),
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.violet,
      secondary: AppColors.magenta,
      surface: AppColors.void1,
      onSurface: AppColors.text,
      onPrimary: Colors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fallback,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
    );
    return base.copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.void2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 28,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: AppColors.violet,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lavender,
          minimumSize: const Size(44, 44),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lavender,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
        fontFamily: fontFamily,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.void2.withValues(alpha: 0.95),
        contentTextStyle: const TextStyle(
          color: AppColors.text,
          fontFamily: fontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        hintStyle: TextStyle(color: AppColors.textFaint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.violetLight,
            width: 1.4,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NebulaTransitions(),
          TargetPlatform.iOS: _NebulaTransitions(),
          TargetPlatform.windows: _NebulaTransitions(),
          TargetPlatform.macOS: _NebulaTransitions(),
          TargetPlatform.linux: _NebulaTransitions(),
        },
      ),
    );
  }
}

class _SwipeEverywhere extends MaterialScrollBehavior {
  const _SwipeEverywhere();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}

/// 3D depth transition: the new screen swings forward out of the nebula
/// while the old one recedes behind it. Respects reduced motion.
class _NebulaTransitions extends PageTransitionsBuilder {
  const _NebulaTransitions();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 460);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return child;
    }
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: enter,
      child: AnimatedBuilder(
        animation: enter,
        child: AppTheme.recede(context, secondaryAnimation, child),
        builder: (context, child) {
          final rise = 1 - enter.value;
          // Settled screens get a plain identity transform, so they add no
          // perspective to the 3D effects inside them.
          return Transform(
            alignment: Alignment.center,
            transform: rise == 0
                ? Matrix4.identity()
                : (Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..translateByDouble(0, rise * 36, 0, 1)
                    ..rotateX(rise * 0.14)
                    ..scaleByDouble(1 - rise * 0.05, 1 - rise * 0.05, 1, 1)),
            child: child,
          );
        },
      ),
    );
  }
}

class Txt {
  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.65,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.3,
  );
  static const h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );
  static const bangla = TextStyle(
    fontFamily: 'HindSiliguri',
    fontWeight: FontWeight.w700,
  );
}

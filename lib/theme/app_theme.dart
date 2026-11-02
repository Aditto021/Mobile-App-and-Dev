import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens for ফেরিওয়ালা .com — "violet space glass".
class AppColors {
  static const void0 = Color(0xFF090812);
  static const void1 = Color(0xFF100F1C);
  static const void2 = Color(0xFF1B192B);

  static const violet = Color(0xFF7C3AED);
  static const violetLight = Color(0xFFA78BFA);
  static const lavender = Color(0xFFDDD6FE);
  static const magenta = Color(0xFFD946EF);
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
    colors: [Color(0xFF8054F6), Color(0xFFB45CE4), Color(0xFF55C6D8)],
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
    colors: [Color(0xFFFFF7E9), Color(0xFFD8C7FF), Color(0xFFFFB8D8)],
  );
}

class AppTheme {
  static const fontFamily = 'Poppins';
  static const fallback = ['HindSiliguri'];

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

/// A short fade and gentle vertical transition, respecting reduced motion.
class _NebulaTransitions extends PageTransitionsBuilder {
  const _NebulaTransitions();

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
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}

class Txt {
  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const small = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const bangla = TextStyle(
    fontFamily: 'HindSiliguri',
    fontWeight: FontWeight.w700,
  );
}

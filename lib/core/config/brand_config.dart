/// MODULE: Brand config — Every brand value (name, tagline, voucher, delivery
/// fee, support contact) in one place, so the app can be renamed by editing
/// only this file.
///
/// Contains: Brand.
library;

// ============================================================
//  BRAND CONFIG — the ONE place to rename the app.
//
//  1. Edit the values below.
//  2. Run:  dart run tool/apply_brand.dart
//     (copies the name into the Android app label, web title,
//      web manifest and pubspec description).
//  3. Rebuild the APK.
// ============================================================

class Brand {
  /// Full display name (Android launcher label, web title, about page).
  static const appName = 'feriWala';

  /// Word mark is drawn as [wordmarkMain] + [wordmarkSuffix].
  static const wordmarkMain = 'feriWala';
  static const wordmarkSuffix = '';

  /// Bengali line shown under the logo on the splash screen.
  static const banglaTagline = 'আপনার পছন্দ, আপনার দরজায়';

  static const tagline = 'Discover it. Love it. Bring it home.';
  static const description = 'feriWala — premium e-commerce';

  /// Welcome voucher advertised on the home screen and accepted in the cart.
  static const couponCode = 'FERIWALA10';
  static const couponPercent = 10;
  static const couponMaxDiscount = 1500;

  static const freeDeliveryOver = 2000;
  static const deliveryFee = 60;

  static const supportEmail = 'support@feriwala.com';
  static const supportPhone = '16xxx';
  static const orderPrefix = 'FW';
}

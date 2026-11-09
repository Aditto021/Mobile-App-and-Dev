# FeriWala — Viva Guide

CSE 464 final project · Group G-10 · IUB. A Daraz-style e-commerce app in
Flutter: 194 products in 24 categories, prices in Taka (৳).

Open `FINAL PROJECT/FeriWala.code-workspace` in VS Code to see the project
with build clutter hidden. Every Dart file starts with a `/// MODULE:` header
that names the module and lists its classes.

---

## 1. Architecture in one picture

```
            main.dart  ──►  app.dart (MaterialApp)
                │                 │
   creates Shop │                 ▼
   (Provider)   │          SplashScreen ─► Onboarding ─► Auth ─► MainShell
                ▼                                                 │
   data/state/shop_state.dart ◄── every screen reads/writes ──────┤
        │   uses data/models/*                                    ▼
        ▼                                    Home · Explore · Cart · Wishlist · Account
   shared_preferences                             │
   (saved on the phone)                Product detail, Search, Checkout,
                                       Order success, Orders, Notifications
```

Three layers:

| Layer | Folder | Job |
|---|---|---|
| Presentation | `features/`, `shared/widgets/` | Screens and reusable widgets |
| State | `data/state/shop_state.dart` | One `ChangeNotifier` (`Shop`) holding all app state |
| Data | `data/models/`, `assets/data/products.json` | Plain Dart model classes + JSON catalogue |
| Core | `core/` | Brand config, theme, validators, formatters, services |

---

## 2. Every module

### Entry
| File | Module |
|---|---|
| `main.dart` | **Entry point** — status bar style, portrait lock, creates `Shop` with `ChangeNotifierProvider`, `runApp` |
| `app.dart` | **App root** — `ShopApp` (`MaterialApp`): title, dark theme, shared background layers, starts at `SplashScreen` |

### core/
| File | Module |
|---|---|
| `config/brand_config.dart` | **Brand config** — `Brand`: app name, tagline, voucher `FERIWALA10` (10 %, max ৳1,500), free delivery over ৳2,000, ৳60 fee |
| `theme/app_theme.dart` | **App theme** — `AppColors` (palette), `AppTheme` (Material theme), `Txt` (text styles), nebula page transition |
| `utils/validators.dart` | **Form validators** — `Validators`: name, email, BD phone, password (+ strength), confirm, postcode, card (Luhn), expiry, CVV |
| `utils/formatters.dart` | **Formatters** — `taka()` (৳12,34,567 grouping), `plural()` |
| `services/app_update_service.dart` | **App update service** — checks a GitHub release feed, downloads + verifies a newer APK |
| `services/display_performance_service.dart` | **Display performance** — asks Android for 90/120 Hz |

### data/
| File | Module |
|---|---|
| `models/product.dart` | **Product** — id, title, price, discount, rating, stock, images, reviews; `originalPrice` is computed from the discount |
| `models/review.dart` | **Review** — rating, comment, name |
| `models/category.dart` | **Category** — `CategoryInfo` list (English + Bangla name, icon, colour), `categoryOf(id)` |
| `models/cart_item.dart` | **CartItem** — product + quantity |
| `models/order.dart` | **Order** — lines, total, payment, address; `status` advances one step per minute (simulated tracking); `toJson`/`fromJson` |
| `models/models.dart` | Barrel file — one import for all models |
| `state/shop_state.dart` | **Shop state** — catalogue, cart, wishlist, orders, recent searches, account; saves everything with `shared_preferences` |

### features/ (screens)
| Folder | Screen | What to show in the demo |
|---|---|---|
| `splash/` | `SplashScreen` | Logo animation while products load; routes to onboarding / auth / shell |
| `onboarding/` | `OnboardingScreen` | 3 `PageView` pages, 3D orbiting icons; only on first launch |
| `auth/` | `AuthScreen` | Sign in / sign up `Form`, validators, password-strength meter |
| `shell/` | `Shell` (`main_shell.dart`) | 5 tabs kept alive in a `Stack`, glass bottom bar, cart & wishlist badges |
| `home/` | `HomeScreen` | Banner carousel, categories, flash sale countdown, voucher, top rated, masonry "Just for you" |
| `categories/` | `CategoriesScreen` | Explore tab: category rail + products |
| `products/` | `ProductListScreen`, `ProductDetailScreen` | Sorting; Hero image gallery, colour picker, reviews, add to cart |
| `search/` | `SearchScreen` | Live search, recent + trending searches |
| `cart/` | `CartScreen` | Qty stepper, swipe to delete (`Dismissible`) with undo, voucher, free-delivery bar |
| `checkout/` | `CheckoutScreen`, `OrderSuccessScreen` | Address form, bKash / Nagad / card / cash on delivery, slide-to-pay, confetti |
| `orders/` | `OrdersScreen` | Order history + tracking timeline |
| `wishlist/` | `WishlistScreen` | Hearted products |
| `account/` | `AccountScreen` | Stats, vouchers, live background toggle, help, updates, sign out |
| `notifications/` | `NotificationsScreen` | Offer notifications |

### shared/widgets/
| File | Module |
|---|---|
| `glass_widgets.dart` | **Glass widgets** — `Glass`, `GlassTile`, `GlassIconButton`, `GlowButton`, `Pressable`, `CountBadge`, `GradientText`, `SectionHeader` |
| `common_widgets.dart` | **Common widgets** — `TopBar`, `QtyStepper`, `EmptyState`, `AnimatedCount`, `OrbitRings`; helpers `go()` (navigate), `toast()`, `showGlassSheet()` |
| `product_widgets.dart` | **Product widgets** — `ProductCard`, `ProductImage` (cached network image), `PriceTag`, `RatingRow`, `DiscountChip`, `HeartButton`, `AddButton` |
| `brand_logo.dart` | **Brand logo** — `CycleVendorLogo`, `BrandMark` (+ painter used to generate the launcher icon), `BrandWordmark` |
| `fly_to_cart.dart` | **Fly-to-cart** — `FlyToCart` overlay + `CartTarget`; flies a thumbnail into the cart icon |
| `space_background.dart` | **Space background** — violet nebula behind every screen: GLSL shader (`shaders/nebula.frag`) or painted fallback; scroll parallax |
| `voucher_card.dart` | **Voucher card** — ticket-shaped card (`CustomClipper`) with copy-code button |

---

## 3. How the app works (talk through this in order)

1. **Start** — `main()` creates one `Shop` and calls `load()`: it reads
   `assets/data/products.json`, then restores the saved cart, wishlist,
   orders, login and address from `shared_preferences`.
2. **Splash** waits for `shop.ready`, then picks the next screen:
   not onboarded → Onboarding; no user → Auth; else → Shell.
3. **Shell** holds the 5 tabs. Tabs are built the first time they are opened
   and then kept alive, so switching back is instant.
4. **Any change** (add to cart, heart, place order) calls a `Shop` method →
   `_changed()` saves to the phone and calls `notifyListeners()` → every
   widget that watches `Shop` rebuilds.
5. **Checkout** validates the forms, `placeOrder()` turns the cart into an
   `Order`, clears the cart and opens the success screen.

---

## 4. Likely viva questions

**Which state management did you use, and why?**
Provider with one `ChangeNotifier` (`Shop`). It is simple, officially
recommended for apps this size, and keeps all business logic out of the UI.
Widgets use `context.watch<Shop>()` to rebuild, `context.read<Shop>()` inside
button callbacks (no rebuild), and `context.select` when they need just one
value (e.g. the nav-bar badge only rebuilds when `cartCount` changes).

**How is data saved?**
`shared_preferences` (key–value storage on the phone). Cart and orders are
stored as JSON strings (`Order.toJson` / `Order.fromJson`). Damaged saved data
is skipped instead of crashing the app.

**Where do products come from?**
A local JSON file in `assets/`, loaded with `rootBundle.loadString` and
converted with `Product.fromJson`. Images load from the internet through
`cached_network_image`, which caches them on the device.

**How does form validation work?**
Each `TextFormField` has a `validator:` from `Validators`; it returns an error
string or `null`. `formKey.currentState!.validate()` runs all of them.
The card number uses the Luhn checksum; phone numbers must be valid Bangladesh
operator prefixes (013–019).

**How is the price calculated?**
`subtotal` = Σ price × qty. Delivery is ৳60, free over ৳2,000. Voucher
`FERIWALA10` gives 10 %, capped at ৳1,500. `total = subtotal + delivery − discount`.

**How does order tracking work without a server?**
`Order.status` is computed from the time since the order was placed:
placed → packed → shipped → delivered, one step per minute.

**StatelessWidget vs StatefulWidget — where did you use each?**
Stateless for pure display (`CartScreen`, `ProductCard`'s parts, `TopBar`).
Stateful when the widget owns something with a lifecycle: form controllers
(`AuthScreen`, `CheckoutScreen`), animation controllers (`SplashScreen`,
`OrderSuccessScreen`), page controllers (`OnboardingScreen`). All controllers
are disposed in `dispose()`.

**Which animations did you use?**
Implicit (`AnimatedOpacity`, `AnimatedScale`, `AnimatedPositioned`),
explicit (`AnimationController` + `AnimatedBuilder`), `Hero` transitions for
product images, `flutter_animate` for entrance effects, `CustomPainter` for
the drawn checkmark and logo, `confetti` on order success, and a GLSL
fragment shader for the live nebula.

**How do you rename the app?**
Edit `core/config/brand_config.dart`, then run `build_apk.ps1`; its
`tool/apply_brand.dart` step copies the name into the Android label and web
title.

**How did you test it?**
`flutter test` runs 36 tests: validators, cart/voucher maths and save/restore
(`shop_test.dart`), update-feed checks, and every screen rendered on a small
phone at 1.4× text size to make sure nothing overflows
(`presentation_test.dart`). `flutter analyze` reports no issues.

**What would you add with more time?**
A real backend (Firebase / REST API) for accounts, products and payments;
real payment gateway integration; push notifications for order status.

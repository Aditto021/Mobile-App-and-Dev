# Google Play release kit — feriWala

Everything Play Console asks for, in the order it asks. Files in this folder:

| File | Play Console field |
|---|---|
| `icon-512.png` | App icon (512 × 512) |
| `feature-graphic.png` | Feature graphic (1024 × 500) |
| `screenshots/1-6*.png` | Phone screenshots (1080 × 1920, 9:16) |
| `../release/play/feriWala-v<version>-<code>.aab` | App bundle (built by `scripts/build_play.ps1`, not committed) |

## 1. Build the bundle

1. Host the backend (section 7) and note its `https://` address.
2. From the app folder:
   ```
   ./scripts/build_play.ps1 -ApiUrl https://your-api.example.com
   ```
   The script runs analyze and tests, builds the `.aab`, and refuses to finish if the bundle is debug-signed, asks to install packages, or allows plain http.
   Without `-ApiUrl` the app runs on the phone only (guest-style accounts, no sync).
3. For every new upload, raise both parts of `version:` in `pubspec.yaml` (e.g. `1.2.1+5`). Play rejects a version code it has seen before.

**Upload key:** `FINAL PROJECT/keys/feriwala-upload.jks`, with its password in `app/android/key.properties` (backup: `keys/key.properties.backup`). Neither is in Git. Keep a copy somewhere safe (USB / Drive). On the first upload, accept **Play App Signing**: Google keeps the real app-signing key, so a lost upload key can be reset through Play support.

## 2. Create the app

- App name: **feriWala**
- Default language: English (United States) — add Bengali later if you translate the listing
- App or game: **App** · Free or paid: **Free**

## 3. Store listing

**Short description** (80 max):
> Phones, gadgets, fashion and beauty in Taka — a student-made shopping app.

**Full description** (4000 max):
> feriWala brings Bangladesh's favourite products together in one smooth, modern app — named after the feriwala, the cycle vendor who brings the market to your door.
>
> • Over 200 products in 14 categories: phones, laptops, gadgets, tablets, watches, smartwatches, fragrance, beauty, skin care, men's and women's fashion, bags, jewellery and shoes
> • Prices in Taka, with discounts, ratings, sales figures and the seller for every product
> • Search in English or Bangla (ফোন, ঘড়ি, ব্যাগ …)
> • Wishlist and cart that follow your account to every device
> • Voucher FERIWALA10: 10% off your order, up to ৳1,500; free delivery from ৳2,000
> • Checkout with bKash, Nagad, card or cash on delivery, then live order tracking
> • Works offline: browse and build your cart without a connection
> • Shop as a guest, or create an account with your email or mobile number
>
> Please note: feriWala is a university project (CSE 464, Independent University, Bangladesh — Group G-10). Checkout is a demonstration: no money is charged and no goods are shipped. Never enter real card or wallet details.

- App category: **Shopping**
- Contact email: the address in `Brand.supportEmail` (must be a real inbox)
- Website: `https://aditto021.github.io/Mobile-App-and-Dev`
- Privacy policy: `https://aditto021.github.io/Mobile-App-and-Dev/privacy-policy.html`

## 4. App content (Policy → App content)

**Privacy policy** — URL above.

**App access** — *All functionality is available without special access* (guest mode covers everything; reviewers can also create an account in the app).

**Ads** — *No, my app does not contain ads.*

**Content rating** (IARC questionnaire) — category *All other app types*; answer **No** to violence, sexuality, language, controlled substances, gambling; users interact/share content: **No**; shares location: **No**; digital purchases: **No**. Expected rating: Everyone / 3+.

**Target audience** — **18 and over** (keeps the app out of the Families programme; it is a shop).

**News app** — No. **Government app** — No. **Financial features** — *My app doesn't provide any financial features.* **Health** — None.

**Data safety** — for a build with `-ApiUrl` (server accounts):

| Question | Answer |
|---|---|
| Collects or shares required user data types? | **Yes** (collects; shares nothing) |
| Encrypted in transit? | **Yes** (https only in release builds) |
| Way to request deletion? | **Yes** — in the app (Account → Delete account) and `https://aditto021.github.io/Mobile-App-and-Dev/delete-account.html` |
| Personal info → Name | Collected, not shared, **optional**, purpose *Account management* |
| Personal info → Email address | Collected, not shared, optional, *Account management* |
| Personal info → Phone number | Collected (if used to sign up), optional, *Account management* |
| Personal info → Address | Collected, optional, *App functionality* |
| Financial info → Purchase history | Collected, optional, *App functionality* |
| App activity → Other user-generated content / in-app actions (cart, wishlist) | Collected, optional, *App functionality* |
| Everything else (location, contacts, photos, device IDs, payment info, analytics) | **Not collected** |

Data is not processed ephemerally (it is saved), it is not used for ads or analytics, and nothing is shared with third parties.

For a build **without** `-ApiUrl`, nothing leaves the phone: answer *No data collected*.

**Account deletion URL** (asked separately): `https://aditto021.github.io/Mobile-App-and-Dev/delete-account.html`

## 5. Testing before production

New personal developer accounts must run a **closed test with at least 12 testers opted in for 14 days in a row** before Play unlocks production. Upload the `.aab` to *Testing → Closed testing*, add the testers' Gmail addresses (classmates work), share the opt-in link, and keep them installed for 14 days. Then apply for production access.

## 6. Before you press "Publish"

- [ ] Enable GitHub Pages: repository **Settings → Pages → Deploy from a branch → `main` / `/docs`**. Check that the privacy and delete-account links open.
- [ ] Put a real support inbox in `lib/core/config/brand_config.dart` (`supportEmail`) and in `docs/*.html`, then rebuild.
- [ ] Backend hosted on https and the bundle built with `-ApiUrl` (or knowingly ship the offline build).
- [ ] Product photos and seller names come from real marketplace listings, and some photos carry that marketplace's sale banners. Play can remove apps for using other companies' images or brands without permission (Intellectual Property and Impersonation policies). For a public release, use photos you have the right to use, or keep the release to closed testing for the course.

## 7. Hosting the backend

`server/Dockerfile` builds a small container with the API and the catalogue:

```
docker build -f server/Dockerfile -t feriwala-api .
docker run -p 8090:8090 -v feriwala-data:/data feriwala-api
```

Any Docker host that gives you https works (Render, Railway, Fly.io, a VPS behind Caddy). Two rules:
- Attach a **persistent volume at `/data`** — accounts and orders are saved in `/data/db.json`; without a volume they are lost on every redeploy.
- The host provides `PORT`; the server already reads it.

Check it with `https://<your-host>/health`, then build the bundle with that address.

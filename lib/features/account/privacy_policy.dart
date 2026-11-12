/// MODULE: Privacy policy — the policy shown inside the app (Google Play
/// asks for it both in the app and at a public web address; the web copy is
/// docs/privacy-policy.html and must say the same).
///
/// Contains: privacyPolicy, PrivacyPolicySheet.
library;

import 'package:flutter/material.dart';

import '../../core/config/brand_config.dart';
import '../../core/theme/app_theme.dart';

const privacyPolicyUpdated = '12 November 2026';

/// (heading, text) pairs.
const privacyPolicy = <(String, String)>[
  (
    'Who we are',
    '${Brand.appName} is a shopping app made by Group G-10 for the CSE 464 '
        'course at Independent University, Bangladesh. Contact us at '
        '${Brand.supportEmail}.',
  ),
  (
    'What we collect',
    'If you create an account: your name, your email address or mobile '
        'number, your password (kept only as a salted hash, never as '
        'text) and your delivery address.\n'
        'While you shop: your cart, voucher, wishlist and orders (items, '
        'prices, payment method name and delivery address).\n'
        'As a guest, all of this stays on your phone and is never sent to us.',
  ),
  (
    'What we do not collect',
    'Card numbers, CVVs and bKash or Nagad numbers are only checked on '
        'your phone and are never sent or stored — checkout is a '
        'demonstration and no money is charged. We do not collect your '
        'location, contacts, photos or advertising ID, and the app has no '
        'ads, analytics or tracking.',
  ),
  (
    'How we use it',
    'Only to run your account: sign you in, keep your cart and wishlist '
        'the same on every device, and record your orders. We never sell '
        'your data or share it for advertising.',
  ),
  (
    'Others who see some data',
    'Product photos are loaded from the image servers they are published '
        'on. Like any website, those servers receive your IP address when '
        'a photo loads.',
  ),
  (
    'Security',
    'The app talks to our server over HTTPS. Passwords are hashed with '
        'PBKDF2-SHA256 and a random salt, and sign-ins expire after 30 days.',
  ),
  (
    'Keeping and deleting your data',
    'We keep your account until you delete it. Account → Delete account '
        'removes your account, cart, wishlist and order history from our '
        'server at once, and from your phone. You can also ask us to delete '
        'it by emailing ${Brand.supportEmail} from your account email.',
  ),
  (
    'Children',
    'The app is not meant for children under 13, and we do not knowingly '
        'collect their data.',
  ),
  (
    'Changes',
    'If this policy changes, the new version will appear here and on our '
        'website with a new date.',
  ),
];

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Privacy policy', style: Txt.h2),
            const SizedBox(height: 4),
            Text(
              'Updated $privacyPolicyUpdated',
              style: Txt.small.copyWith(color: AppColors.textFaint),
            ),
            for (final (title, body) in privacyPolicy) ...[
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: AppColors.textDim)),
            ],
            const SizedBox(height: 16),
            Text(
              Brand.privacyPolicyUrl,
              style: Txt.small.copyWith(color: AppColors.violetLight),
            ),
          ],
        ),
      ),
    );
  }
}

/// MODULE: Checkout screen — Delivery address form, payment method (card /
/// bKash / Nagad / cash) with validation, and slide-to-pay.
///
/// Contains: _Pay, CheckoutScreen, _CheckoutScreenState, _StepHeader,
/// _AddressCard, AddressForm, _AddressFormState, _PayTile, _CardForm,
/// _CardFormatter, SlideToPay, _SlideToPayState.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/state/shop_state.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/product_widgets.dart';
import 'order_success_screen.dart';

class _Pay {
  final String id, name, sub;
  final IconData icon;
  final Color color;
  const _Pay(this.id, this.name, this.sub, this.icon, this.color);
}

const _methods = [
  _Pay(
    'bkash',
    'bKash',
    'Pay with your bKash wallet',
    Iconsax.wallet_2,
    Color(0xFFE2136E),
  ),
  _Pay(
    'nagad',
    'Nagad',
    'Pay with your Nagad wallet',
    Iconsax.wallet_money,
    Color(0xFFF7941D),
  ),
  _Pay(
    'card',
    'Credit / Debit card',
    'Visa, Mastercard, Amex',
    Iconsax.card,
    AppColors.cyan,
  ),
  _Pay(
    'cod',
    'Cash on delivery',
    'Pay when it arrives',
    Iconsax.money,
    AppColors.mint,
  ),
];

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _method = 'cod';
  final _cardForm = GlobalKey<FormState>();
  final _walletForm = GlobalKey<FormState>();
  final _cardNo = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _wallet = TextEditingController();

  @override
  void dispose() {
    _cardNo.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _wallet.dispose();
    super.dispose();
  }

  bool _validate() {
    final form = switch (_method) {
      'card' => _cardForm,
      'bkash' || 'nagad' => _walletForm,
      _ => null,
    };
    return form?.currentState?.validate() ?? true;
  }

  Future<void> _pay() async {
    if (!mounted) return;
    final shop = context.read<Shop>();
    if (shop.cart.isEmpty) {
      toast(context, 'Your cart is empty');
      return;
    }
    final name = _methods.firstWhere((m) => m.id == _method).name;
    final order = shop.placeOrder(name);
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<Shop>();
    return Scaffold(
      body: Column(
        children: [
          const TopBar(title: 'Checkout', subtitle: 'Review your order'),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
              children: [
                const _StepHeader(step: 'Delivery address', n: 1),
                _AddressCard(address: shop.address).entrance(0),
                const SizedBox(height: 22),
                const _StepHeader(step: 'Payment method', n: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Demo checkout · no payment is collected. Use sample payment details only.',
                    style: Txt.small.copyWith(color: AppColors.textFaint),
                  ),
                ),
                for (final (i, m) in _methods.indexed)
                  _PayTile(
                    m: m,
                    selected: m.id == _method,
                    onTap: () => setState(() => _method = m.id),
                  ).entrance(i + 1),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: switch (_method) {
                    'card' => _CardForm(
                      formKey: _cardForm,
                      number: _cardNo,
                      expiry: _expiry,
                      cvv: _cvv,
                    ),
                    'bkash' || 'nagad' => Form(
                      key: _walletForm,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: TextFormField(
                          controller: _wallet,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText:
                                '${_method == 'bkash' ? 'bKash' : 'Nagad'} account number',
                            prefixIcon: const Icon(Iconsax.mobile, size: 20),
                          ),
                          validator: Validators.bangladeshNumberValidator,
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),
                    ),
                    _ => const SizedBox(width: double.infinity),
                  },
                ),
                const SizedBox(height: 22),
                _StepHeader(step: 'Order summary', n: 3),
                Glass(
                  radius: 24,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (final c in shop.cart)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: ProductImage(
                                  c.product.thumbnail,
                                  padding: 3,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${c.qty} × ${c.product.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                taka(c.product.price * c.qty),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Divider(color: AppColors.glassBorder),
                      _line(
                        'Delivery',
                        shop.delivery == 0 ? 'FREE' : taka(shop.delivery),
                      ),
                      if (shop.couponDiscount > 0)
                        _line('Voucher', '−${taka(shop.couponDiscount)}'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Total', style: Txt.h3),
                          const Spacer(),
                          GradientText(
                            taka(shop.total),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                if (shop.cart.isNotEmpty)
                  SlideToPay(
                    label: 'Slide to place order',
                    canStart: _validate,
                    onComplete: _pay,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(l, style: TextStyle(color: AppColors.textDim)),
        const Spacer(),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _StepHeader extends StatelessWidget {
  final String step;
  final int n;
  const _StepHeader({required this.step, required this.n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Text(
              '$n',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text(step, style: Txt.h3),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    final shop = context.read<Shop>();
    return Pressable(
      scale: 0.98,
      onTap: () => showGlassSheet(context, const AddressForm()),
      child: GlassTile(
        radius: 22,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Iconsax.location, color: AppColors.violetLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.userName ?? 'Home',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: Txt.small.copyWith(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.edit_2, size: 18, color: AppColors.violetLight),
          ],
        ),
      ),
    );
  }
}

/// Address editor — validated with the shared [Validators].
class AddressForm extends StatefulWidget {
  const AddressForm({super.key});

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: context.read<Shop>().userName == 'Guest'
        ? ''
        : context.read<Shop>().userName,
  );
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController(text: 'Dhaka');
  final _post = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _phone, _street, _city, _post]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Delivery address', style: Txt.h2),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              hintText: 'Full name',
              prefixIcon: Icon(Iconsax.user, size: 20),
            ),
            validator: Validators.nameValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Phone (01XXXXXXXXX)',
              prefixIcon: Icon(Iconsax.call, size: 20),
            ),
            validator: Validators.bangladeshNumberValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _street,
            decoration: const InputDecoration(
              hintText: 'House, road, area',
              prefixIcon: Icon(Iconsax.location, size: 20),
            ),
            validator: (v) => Validators.minLengthValidator(v, 5, 'Address'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _city,
                  decoration: const InputDecoration(hintText: 'City'),
                  validator: (v) => Validators.requiredValidator(v, 'City'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _post,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Postcode'),
                  validator: Validators.postcodeValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlowButton(
            label: 'Save address',
            onTap: () {
              if (!_form.currentState!.validate()) return;
              context.read<Shop>().setAddress(
                '${_street.text.trim()}, ${_city.text.trim()} ${_post.text.trim()} · ${_phone.text.trim()}',
              );
              Navigator.of(context).pop();
              toast(context, 'Address saved');
            },
          ),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  final _Pay m;
  final bool selected;
  final VoidCallback onTap;
  const _PayTile({
    required this.m,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        scale: 0.98,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                (selected ? m.color : Colors.white).withValues(
                  alpha: selected ? 0.22 : 0.07,
                ),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: selected
                  ? m.color.withValues(alpha: 0.8)
                  : AppColors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: m.color.withValues(alpha: 0.35),
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(m.icon, color: m.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      m.sub,
                      style: Txt.small.copyWith(
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? m.color : Colors.transparent,
                  border: Border.all(
                    color: selected ? m.color : Colors.white38,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      ).animate().scale(
                        curve: Curves.elasticOut,
                        duration: 500.ms,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController number, expiry, cvv;
  const _CardForm({
    required this.formKey,
    required this.number,
    required this.expiry,
    required this.cvv,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Column(
          children: [
            TextFormField(
              controller: number,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardFormatter(),
              ],
              decoration: const InputDecoration(
                hintText: 'Card number',
                prefixIcon: Icon(Iconsax.card, size: 20),
              ),
              validator: Validators.cardNumberValidator,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: expiry,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'MM/YY'),
                    validator: Validators.expiryValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: cvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'CVV'),
                    validator: Validators.cvvValidator,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.2),
    );
  }
}

/// Groups card digits as 4-4-4-4.
class _CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(digits[i]);
    }
    final s = b.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

/// Drag the glowing orb to the end to confirm payment. Springs back if
/// released early; morphs into a spinner, then completes.
class SlideToPay extends StatefulWidget {
  final String label;
  final bool Function() canStart;
  final Future<void> Function() onComplete;
  const SlideToPay({
    super.key,
    required this.label,
    required this.canStart,
    required this.onComplete,
  });

  @override
  State<SlideToPay> createState() => _SlideToPayState();
}

class _SlideToPayState extends State<SlideToPay>
    with SingleTickerProviderStateMixin {
  double _x = 0;
  bool _busy = false;
  bool _allowed = false;
  late final AnimationController _back =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..addListener(
        () => setState(
          () => _x = _from * (1 - Curves.elasticOut.transform(_back.value)),
        ),
      );
  double _from = 0;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const h = 64.0;
    return LayoutBuilder(
      builder: (context, box) {
        final max = (box.maxWidth - h).clamp(1.0, double.infinity);
        final pct = (_x / max).clamp(0.0, 1.0);
        return Container(
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h / 2),
            gradient: LinearGradient(
              colors: [
                AppColors.violet.withValues(alpha: 0.35 + pct * 0.4),
                AppColors.magenta.withValues(alpha: 0.2 + pct * 0.5),
              ],
            ),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.3 + pct * 0.4),
                blurRadius: 24,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Opacity(
                  opacity: _busy ? 0 : 1 - pct,
                  child:
                      Text(
                            widget.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1800.ms, color: Colors.white),
                ),
              ),
              if (_busy)
                const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              Positioned(
                left: _busy ? max / 2 : _x,
                child: GestureDetector(
                  onHorizontalDragStart: (_) {
                    _allowed = widget.canStart();
                    if (!_allowed) {
                      HapticFeedback.heavyImpact();
                      toast(
                        context,
                        'Please complete your payment details',
                        icon: Icons.error_outline_rounded,
                      );
                    }
                  },
                  onHorizontalDragUpdate: (d) {
                    if (_busy || !_allowed) return;
                    setState(() => _x = (_x + d.delta.dx).clamp(0, max));
                    if (_x >= max) HapticFeedback.lightImpact();
                  },
                  onHorizontalDragEnd: (_) async {
                    if (_busy || !_allowed) return;
                    if (_x >= max * 0.92) {
                      HapticFeedback.heavyImpact();
                      setState(() => _busy = true);
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!mounted) return;
                      await widget.onComplete();
                    } else {
                      _from = _x;
                      _back.forward(from: 0);
                    }
                  },
                  child: AnimatedOpacity(
                    opacity: _busy ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: h,
                      height: h,
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.magenta.withValues(alpha: 0.8),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.arrow_right_3,
                          color: AppColors.violet,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

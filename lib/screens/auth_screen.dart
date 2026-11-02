import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../data/shop.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/brand.dart';
import '../widgets/glass.dart';
import 'shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _signUp = false;
  bool _obscure = true;
  bool _loading = false;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _enter(String name, String email) {
    context.read<Shop>().signIn(name, email);
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Shell()), (_) => false);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final email = _email.text.trim();
    final name = _signUp && _name.text.trim().isNotEmpty ? _name.text.trim() : _nameFromEmail(email);
    _enter(name, email);
  }

  String _nameFromEmail(String e) {
    final n = e.split('@').first.replaceAll(RegExp(r'[._\d]+'), ' ').trim();
    if (n.isEmpty) return 'Shopper';
    return n.split(' ').first[0].toUpperCase() + n.split(' ').first.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              children: [
                const BrandMark(size: 110).animate().scale(curve: Curves.elasticOut, duration: 1000.ms),
                const SizedBox(height: 6),
                const BrandWordmark(size: 30).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3),
                const SizedBox(height: 26),
                Glass(
                  radius: 32,
                  blur: 24,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Toggle(signUp: _signUp, onChanged: (v) => setState(() => _signUp = v)),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          layoutBuilder: (cur, prev) =>
                              Stack(alignment: Alignment.centerLeft, children: [...prev, ?cur]),
                          child: Text(
                            _signUp ? 'Create your account ✨' : 'Welcome back 👋',
                            key: ValueKey(_signUp),
                            style: Txt.h2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _signUp ? 'Join millions shopping smarter.' : 'Sign in to continue shopping.',
                          style: Txt.small.copyWith(color: AppColors.textDim),
                        ),
                        const SizedBox(height: 20),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          child: _signUp
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    controller: _name,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      hintText: 'Full name',
                                      prefixIcon: Icon(Iconsax.user, size: 20),
                                    ),
                                    validator: (v) => _signUp ? Validators.nameValidator(v) : null,
                                  ).animate().fadeIn().slideY(begin: -0.3),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            hintText: 'Email or phone',
                            prefixIcon: Icon(Iconsax.sms, size: 20),
                          ),
                          validator: Validators.emailOrPhoneValidator,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pass,
                          obscureText: _obscure,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Iconsax.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Iconsax.eye_slash : Iconsax.eye, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              _signUp ? Validators.passwordValidator(v) : Validators.requiredValidator(v, 'Password'),
                        ),
                        if (_signUp) ...[
                          _StrengthMeter(score: Validators.passwordStrength(_pass.text)),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure,
                            decoration: const InputDecoration(
                              hintText: 'Confirm password',
                              prefixIcon: Icon(Iconsax.lock_1, size: 20),
                            ),
                            validator: (v) => Validators.confirmPasswordValidator(_pass.text, v),
                          ).animate().fadeIn().slideY(begin: -0.3),
                        ],
                        if (!_signUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(color: AppColors.violetLight, fontSize: 12.5),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _loading
                              ? const SizedBox(
                                  height: 56,
                                  child: Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.violetLight),
                                    ),
                                  ),
                                )
                              : GlowButton(label: _signUp ? 'Create account' : 'Sign in', onTap: _submit),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.glassBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or', style: Txt.small.copyWith(color: AppColors.textFaint)),
                            ),
                            Expanded(child: Divider(color: AppColors.glassBorder)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Pressable(
                          onTap: () => _enter('Guest', ''),
                          child: Glass(
                            radius: 28,
                            opacity: 0.06,
                            child: const SizedBox(
                              height: 52,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Iconsax.user_octagon, size: 20),
                                  SizedBox(width: 10),
                                  Text('Continue as guest', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 600.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Five-segment password strength bar (score from Validators.passwordStrength).
class _StrengthMeter extends StatelessWidget {
  final int score;
  const _StrengthMeter({required this.score});

  static const _labels = ['', 'Very weak', 'Weak', 'Fair', 'Strong', 'Very strong'];
  static const _colors = [
    Colors.transparent,
    AppColors.rose,
    Color(0xFFFB923C),
    AppColors.gold,
    AppColors.violetLight,
    AppColors.mint,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++)
            Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250 + i * 60),
                curve: Curves.easeOutCubic,
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= score ? _colors[score] : Colors.white.withValues(alpha: 0.1),
                  boxShadow: i <= score
                      ? [BoxShadow(color: _colors[score].withValues(alpha: 0.6), blurRadius: 6)]
                      : null,
                ),
              ),
            ),
          SizedBox(
            width: 78,
            child: Text(
              _labels[score],
              textAlign: TextAlign.right,
              style: Txt.small.copyWith(fontSize: 11, color: _colors[score]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool signUp;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.signUp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: signUp ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.6), blurRadius: 14)],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, l) in ['Sign in', 'Sign up'].indexed)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i == 1),
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (i == 1) == signUp ? Colors.white : AppColors.textDim,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

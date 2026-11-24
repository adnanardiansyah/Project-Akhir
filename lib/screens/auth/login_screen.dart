import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/form_validators.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/password_field.dart';
import 'partner_registration_screen.dart';
import 'register_screen.dart';

/// Layar Masuk (Login) Modern dengan Desain Emerald Premium.
class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final AppServices? services;

  const LoginScreen({
    super.key,
    required this.authService,
    this.services,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, errorMessageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(authService: widget.authService),
      ),
    );
  }

  void _openPartnerRegistration() {
    final services = widget.services;
    if (services == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartnerRegistrationScreen(services: services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmeraldColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Intro
                    FadeSlideIn(
                      child: Column(
                        children: [
                          const BrandMark(size: 80),
                          const SizedBox(height: 20),
                          Text(
                            'Food Order Lhokseumawe',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: EmeraldColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Emerald Premium Food Delivery Experience',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: EmeraldColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form Container Card
                    FadeSlideIn(
                      index: 1,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: EmeraldColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Masuk ke Akun',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: EmeraldColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Alamat Email',
                                hintText: 'contoh@email.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: validateEmail,
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            PasswordField(
                              controller: _passwordController,
                              label: 'Kata Sandi',
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: validatePassword,
                            ),

                            const SizedBox(height: 24),

                            // Tombol Masuk
                            LoadingButton(
                              label: 'Masuk Sekarang',
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Navigation to Register
                    FadeSlideIn(
                      index: 2,
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : _openRegister,
                            child: RichText(
                              text: TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  color: EmeraldColors.textSecondary,
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Daftar Pemesan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: EmeraldColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: EmeraldColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading || widget.services == null
                                ? null
                                : _openPartnerRegistration,
                            icon: const Icon(
                              Icons.handshake_outlined,
                              size: 18,
                              color: EmeraldColors.primary,
                            ),
                            label: const Text(
                              'Daftar sebagai Mitra Restoran / Kurir',
                              style: TextStyle(
                                color: EmeraldColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/form_validators.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/password_field.dart';
import 'register_screen.dart';

// Layar masuk dengan email dan kata sandi
class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Status form masuk: isian, validasi, dan tanda sedang memuat
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

  // Validasi form lalu masuk; galat ditampilkan lewat SnackBar
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

  // Membuka layar pendaftaran pemesan
  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FadeSlideIn(
                  child: AuthHeader(
                    title: 'Selamat datang',
                    subtitle:
                        'Masuk untuk memesan makanan dari resto favoritmu.',
                  ),
                ),
                const SizedBox(height: 36),
                FadeSlideIn(
                  index: 1,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: validateEmail,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 2,
                  child: PasswordField(
                    controller: _passwordController,
                    label: 'Kata sandi',
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: validatePassword,
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  index: 3,
                  child: LoadingButton(
                    label: 'Masuk',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 4,
                  child: TextButton(
                    onPressed: _isLoading ? null : _openRegister,
                    child: const Text(
                      'Belum punya akun? Daftar sebagai pemesan',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

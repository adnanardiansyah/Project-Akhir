import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/form_validators.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/error_snack_bar.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/password_field.dart';

// Layar pendaftaran akun pemesan
class RegisterScreen extends StatefulWidget {
  final AuthService authService;

  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Status form daftar: isian, validasi, dan tanda sedang memuat
class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Validasi form lalu daftar; setelah berhasil kembali ke akar agar app.dart mengalihkan layar
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await widget.authService.registerCustomer(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, errorMessageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FadeSlideIn(
                  child: AuthHeader(
                    title: 'Buat akun pemesan',
                    subtitle: 'Daftar sekali, lalu pesan dari resto mana saja.',
                  ),
                ),
                const SizedBox(height: 32),
                FadeSlideIn(
                  index: 1,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: validateDisplayName,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 2,
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
                  index: 3,
                  child: PasswordField(
                    controller: _passwordController,
                    label: 'Kata sandi',
                    validator: validatePassword,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 4,
                  child: PasswordField(
                    controller: _confirmController,
                    label: 'Ulangi kata sandi',
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) => validatePasswordConfirmation(
                      value,
                      _passwordController.text,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  index: 5,
                  child: LoadingButton(
                    label: 'Daftar',
                    isLoading: _isLoading,
                    onPressed: _submit,
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

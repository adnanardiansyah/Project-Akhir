import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/state_message.dart';

// Beranda resto; daftar pesanan masuk diisi di L5
class IncomingOrdersScreen extends StatelessWidget {
  final AppUser user;
  final AuthService authService;

  const IncomingOrdersScreen({
    super.key,
    required this.user,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
        actions: [LogoutButton(authService: authService)],
      ),
      body: const StateMessage(
        icon: Icons.receipt_long_rounded,
        title: 'Pesanan Masuk',
        message: 'Pesanan dari pemesan akan tampil di sini.',
      ),
    );
  }
}

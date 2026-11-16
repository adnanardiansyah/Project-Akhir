import 'package:flutter/material.dart';

import '../services/auth_service.dart';

// Tombol keluar di AppBar, dipakai layar pemesan dan resto
class LogoutButton extends StatelessWidget {
  final AuthService authService;

  const LogoutButton({super.key, required this.authService});

  // Tutup semua layar tumpukan lalu keluar, agar yang tersisa layar login
  Future<void> _logout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    try {
      await authService.signOut();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal keluar, coba lagi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Keluar',
      onPressed: () => _logout(context),
    );
  }
}

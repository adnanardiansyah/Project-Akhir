import 'package:flutter/material.dart';

// Menampilkan pesan galat singkat di bagian bawah layar
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

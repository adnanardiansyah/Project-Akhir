import 'package:flutter/material.dart';

// Metode bayar simulasi (K3): tidak ada uang sungguhan yang berpindah
// COD dibayar kurir saat pesanan tiba, bukan saat pesanan dibuat
enum PaymentMethod { ewallet, bankTransfer, cod }

// Label, keterangan, dan ikon tiap metode untuk tampilan
extension PaymentMethodInfo on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.ewallet => 'E-Wallet',
    PaymentMethod.bankTransfer => 'Transfer Bank',
    PaymentMethod.cod => 'COD (Bayar di Tempat)',
  };

  String get description => switch (this) {
    PaymentMethod.ewallet => 'Saldo dompet digital (simulasi)',
    PaymentMethod.bankTransfer => 'Virtual account (simulasi)',
    PaymentMethod.cod => 'Bayar tunai saat kurir tiba',
  };

  IconData get icon => switch (this) {
    PaymentMethod.ewallet => Icons.account_balance_wallet_rounded,
    PaymentMethod.bankTransfer => Icons.account_balance_rounded,
    PaymentMethod.cod => Icons.money_rounded,
  };
}

// COD tetap tercatat sebagai metode bayar meski paymentStatus belum paid
bool isCodMethodName(String? name) => name == PaymentMethod.cod.name;

// Membaca metode dari nilai tersimpan; null bila kosong atau tidak dikenal
PaymentMethod? paymentMethodFromName(String? name) =>
    PaymentMethod.values.asNameMap()[name];

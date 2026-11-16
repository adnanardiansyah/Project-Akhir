import 'package:flutter/material.dart';

// Metode bayar simulasi (K3): tidak ada uang sungguhan yang berpindah
enum PaymentMethod { ewallet, bankTransfer }

// Label, keterangan, dan ikon tiap metode untuk tampilan
extension PaymentMethodInfo on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.ewallet => 'E-Wallet',
    PaymentMethod.bankTransfer => 'Transfer Bank',
  };

  String get description => switch (this) {
    PaymentMethod.ewallet => 'Saldo dompet digital (simulasi)',
    PaymentMethod.bankTransfer => 'Virtual account (simulasi)',
  };

  IconData get icon => switch (this) {
    PaymentMethod.ewallet => Icons.account_balance_wallet_rounded,
    PaymentMethod.bankTransfer => Icons.account_balance_rounded,
  };
}

// Membaca metode dari nilai tersimpan; null bila kosong atau tidak dikenal
PaymentMethod? paymentMethodFromName(String? name) =>
    PaymentMethod.values.asNameMap()[name];

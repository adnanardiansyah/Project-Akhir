// Mengubah bilangan bulat rupiah menjadi teks, misalnya 15000 -> "Rp 15.000"
String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    // Titik pemisah ribuan disisipkan setiap tiga digit dari kanan
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '${sign}Rp $buffer';
}

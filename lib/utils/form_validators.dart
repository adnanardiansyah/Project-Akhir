// Panjang minimal kata sandi yang diterima Firebase Authentication
const int minPasswordLength = 6;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Validasi email: wajib diisi dan berformat email
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi';
  if (!_emailPattern.hasMatch(email)) return 'Format email tidak valid';
  return null;
}

// Validasi kata sandi: wajib diisi dan minimal 6 karakter
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Kata sandi wajib diisi';
  if (password.length < minPasswordLength) {
    return 'Kata sandi minimal $minPasswordLength karakter';
  }
  return null;
}

// Validasi nama tampilan: wajib diisi
String? validateDisplayName(String? value) {
  if ((value?.trim() ?? '').isEmpty) return 'Nama wajib diisi';
  return null;
}

// Validasi konfirmasi kata sandi: harus sama dengan kata sandi
String? validatePasswordConfirmation(String? value, String password) {
  if ((value ?? '').isEmpty) return 'Ulangi kata sandi';
  if (value != password) return 'Kata sandi tidak sama';
  return null;
}

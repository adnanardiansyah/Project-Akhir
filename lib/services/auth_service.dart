import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

// Pesan galat umum bila penyebab galat tidak dikenali
const String genericErrorMessage = 'Terjadi kesalahan, coba lagi';

// Akses login Firebase Authentication dan profil di koleksi users
class AuthService {
  // Instance Firebase diambil saat dipakai agar layar bisa dites tanpa Firebase
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Aliran status login (null berarti belum login)
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Aliran profil users/{uid}; null bila dokumen tidak ada atau peran tidak dikenal
  Stream<AppUser?> watchAppUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : AppUser.fromMap(uid, data);
    });
  }

  // Masuk dengan email dan kata sandi
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Mendaftar akun baru yang selalu berperan pemesan (U4)
  Future<void> registerCustomer({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'role': 'customer',
        'displayName': displayName.trim(),
      });
    } catch (_) {
      // Profil gagal ditulis: hapus akun baru agar tidak ada akun tanpa profil
      await _discardUser(user);
      rethrow;
    }
  }

  // Menghapus akun yang baru dibuat; bila gagal, setidaknya keluar
  Future<void> _discardUser(User user) async {
    try {
      await user.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  // Keluar dari akun
  Future<void> signOut() => _auth.signOut();
}

// Mengubah kode galat Firebase Authentication menjadi pesan bahasa Indonesia
String authErrorMessage(String code) {
  return switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email atau kata sandi salah',
    'invalid-email' => 'Format email tidak valid',
    'email-already-in-use' => 'Email sudah terdaftar',
    'weak-password' => 'Kata sandi terlalu lemah',
    'user-disabled' => 'Akun ini dinonaktifkan',
    'too-many-requests' => 'Terlalu banyak percobaan, coba lagi nanti',
    'network-request-failed' => 'Tidak ada koneksi internet',
    _ => genericErrorMessage,
  };
}

// Pesan untuk galat apa pun dari proses login atau daftar
String errorMessageFor(Object error) {
  return error is FirebaseAuthException
      ? authErrorMessage(error.code)
      : genericErrorMessage;
}

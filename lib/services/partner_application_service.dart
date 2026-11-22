import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/partner_application.dart';

class PartnerApplicationService {
  const PartnerApplicationService();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('partnerApplications');

  // Memantau status pengajuan milik satu akun.
  Stream<PartnerApplication?> watchApplication(String uid) {
    return _applications.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : PartnerApplication.fromMap(uid, data);
    });
  }

  // Mengirim pengajuan baru dari akun pemesan yang sudah masuk.
  Future<void> submitForCurrentCustomer({
    required PartnerApplicationType type,
    required String phone,
    String? restaurantName,
    String? address,
    GeoPoint? location,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email == null) {
      throw StateError('Masuk kembali sebelum mengirim pengajuan.');
    }
    final profile = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final applicantName = profile.data()?['displayName'];
    if (applicantName is! String || applicantName.trim().isEmpty) {
      throw StateError('Profil akun belum lengkap.');
    }
    await _applications.doc(currentUser.uid).set(
      PartnerApplication.pendingData(
        uid: currentUser.uid,
        type: type,
        applicantName: applicantName,
        email: currentUser.email!,
        phone: phone,
        restaurantName: restaurantName,
        address: address,
        location: location,
      ),
    );
  }

  // Mengirim ulang data setelah pengajuan sebelumnya ditolak admin.
  Future<void> resubmit({
    required String uid,
    required PartnerApplicationType type,
    required String applicantName,
    required String phone,
    String? restaurantName,
    String? address,
    GeoPoint? location,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != uid || currentUser.email == null) {
      throw StateError('Masuk kembali sebelum mengirim ulang pengajuan.');
    }
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {
      'displayName': applicantName.trim(),
    });
    batch.set(
      _applications.doc(uid),
      PartnerApplication.pendingData(
        uid: uid,
        type: type,
        applicantName: applicantName,
        email: currentUser.email!,
        phone: phone,
        restaurantName: restaurantName,
        address: address,
        location: location,
      ),
    );
    await batch.commit();
  }
}

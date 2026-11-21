import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import 'firestore_write.dart';

// Chat per pesanan di subkoleksi orders/{orderId}/messages
class ChatService {
  // Instance Firestore diambil saat dipakai agar validasi bisa dites tanpa Firebase
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String orderId) =>
      _firestore.collection('orders').doc(orderId).collection('messages');

  // Aliran pesan urut waktu kirim; kedua pihak mendengarkan koleksi yang sama
  Stream<List<ChatMessage>> watchMessages(String orderId) {
    return _messages(orderId)
        .orderBy('createdAt')
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ChatMessage.fromMap(
                  doc.id,
                  doc.data(),
                  hasPendingWrites: doc.metadata.hasPendingWrites,
                ),
              )
              .whereType<ChatMessage>()
              .toList(),
        );
  }

  // Mengirim pesan; teks kosong atau terlalu panjang ditolak sebelum menyentuh Firestore
  Future<void> sendMessage({
    required String orderId,
    required AppUser sender,
    required String text,
  }) async {
    final normalized = normalizeMessageText(text);
    if (normalized == null) {
      throw ArgumentError('Pesan tidak boleh kosong');
    }
    if (normalized.length > maxMessageLength) {
      throw ArgumentError('Pesan maksimal $maxMessageLength karakter');
    }
    await waitForServerAck(
      _messages(orderId).doc().set({
        'senderUid': sender.uid,
        'senderRole': sender.role.name,
        'text': normalized,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }
}

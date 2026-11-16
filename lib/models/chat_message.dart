import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_user.dart';

// Panjang maksimal satu pesan chat
const int maxMessageLength = 500;

// Merapikan teks pesan; null bila kosong setelah spasi di tepi dibuang
String? normalizeMessageText(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

// Satu pesan dari orders/{orderId}/messages/{messageId}
class ChatMessage {
  final String id;
  final String senderUid;
  final UserRole senderRole;
  final String text;
  // Null sesaat setelah dikirim, sebelum waktu server tercatat
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderRole,
    required this.text,
    this.createdAt,
  });

  // Membaca pesan dari Firestore; null bila field inti tidak valid
  static ChatMessage? fromMap(String id, Map<String, dynamic> data) {
    final senderUid = data['senderUid'];
    final text = data['text'];
    final role = UserRole.values.asNameMap()[data['senderRole']];
    if (senderUid is! String || text is! String || role == null) return null;
    final createdAt = data['createdAt'];
    return ChatMessage(
      id: id,
      senderUid: senderUid,
      senderRole: role,
      text: text,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}

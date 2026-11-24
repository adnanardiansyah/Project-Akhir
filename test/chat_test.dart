import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/models/app_user.dart';
import 'package:food_order_app/models/chat_message.dart';
import 'package:food_order_app/services/chat_service.dart';
import 'package:food_order_app/utils/format_date_time.dart';

const _customer = AppUser(
  uid: 'c1',
  role: UserRole.customer,
  displayName: 'Rian',
);

void main() {
  group('normalizeMessageText', () {
    test('pesan kosong atau spasi saja ditolak', () {
      expect(normalizeMessageText(''), isNull);
      expect(normalizeMessageText('   '), isNull);
      expect(normalizeMessageText('\n\t '), isNull);
    });

    test('spasi di tepi dibuang, isi dipertahankan', () {
      expect(normalizeMessageText('  pedas level 3  '), 'pedas level 3');
    });
  });

  group('ChatService.sendMessage', () {
    // Validasi terjadi sebelum Firestore disentuh, jadi bisa dites tanpa Firebase
    test('pesan kosong ditolak', () {
      expect(
        ChatService().sendMessage(orderId: 'o1', sender: _customer, text: '  '),
        throwsArgumentError,
      );
    });

    test('pesan lebih dari batas ditolak', () {
      expect(
        ChatService().sendMessage(
          orderId: 'o1',
          sender: _customer,
          text: 'a' * (maxMessageLength + 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('ChatMessage.fromMap', () {
    test('membaca pesan lengkap', () {
      final message = ChatMessage.fromMap('m1', {
        'senderUid': 'c1',
        'senderRole': 'customer',
        'text': 'Masih tersedia?',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 17, 7, 5)),
      });
      expect(message!.senderUid, 'c1');
      expect(message.senderRole, UserRole.customer);
      expect(message.text, 'Masih tersedia?');
      expect(
        message.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 17, 7, 5)),
        isTrue,
      );
    });

    test('createdAt kosong (menunggu waktu server) tetap terbaca', () {
      final message = ChatMessage.fromMap('m1', {
        'senderUid': 'r1',
        'senderRole': 'restaurant',
        'text': 'Tersedia',
        'createdAt': null,
      });
      expect(message!.createdAt, isNull);
    });

    test('peran admin dikenal', () {
      final message = ChatMessage.fromMap('m', {
        'senderUid': 'a1',
        'senderRole': 'admin',
        'text': 'hai',
      });
      expect(message!.senderRole, UserRole.admin);
    });

    test('peran tidak dikenal atau field kurang ditolak', () {
      expect(
        ChatMessage.fromMap('m', {
          'senderUid': 'x',
          'senderRole': 'superadmin',
          'text': 'hai',
        }),
        isNull,
      );
      expect(ChatMessage.fromMap('m', {'senderRole': 'customer'}), isNull);
    });
  });

  group('formatTime', () {
    test('jam dan menit dua digit', () {
      expect(formatTime(DateTime(2026, 11, 17, 9, 5)), '09.05');
      expect(formatTime(DateTime(2026, 11, 17, 21, 30)), '21.30');
    });
  });
}

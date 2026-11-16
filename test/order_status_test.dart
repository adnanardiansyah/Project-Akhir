import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/models/order.dart';
import 'package:food_order_app/services/order_service.dart';

void main() {
  group('OrderStatus.canTransitionTo', () {
    test('pending boleh dikonfirmasi atau dibatalkan', () {
      expect(
        OrderStatus.pending.canTransitionTo(OrderStatus.confirmed),
        isTrue,
      );
      expect(
        OrderStatus.pending.canTransitionTo(OrderStatus.cancelled),
        isTrue,
      );
    });

    test('pending tidak boleh langsung dibayar', () {
      expect(OrderStatus.pending.canTransitionTo(OrderStatus.paid), isFalse);
    });

    test('confirmed boleh dibayar atau dibatalkan', () {
      expect(OrderStatus.confirmed.canTransitionTo(OrderStatus.paid), isTrue);
      expect(
        OrderStatus.confirmed.canTransitionTo(OrderStatus.cancelled),
        isTrue,
      );
    });

    test('confirmed tidak boleh kembali ke pending', () {
      expect(
        OrderStatus.confirmed.canTransitionTo(OrderStatus.pending),
        isFalse,
      );
    });

    test('paid tidak bisa berubah, termasuk dibatalkan', () {
      for (final next in OrderStatus.values) {
        expect(
          OrderStatus.paid.canTransitionTo(next),
          isFalse,
          reason: '$next',
        );
      }
    });

    test('cancelled tidak bisa berubah', () {
      for (final next in OrderStatus.values) {
        expect(
          OrderStatus.cancelled.canTransitionTo(next),
          isFalse,
          reason: '$next',
        );
      }
    });

    test('status ke dirinya sendiri tidak dihitung perpindahan', () {
      for (final status in OrderStatus.values) {
        expect(status.canTransitionTo(status), isFalse, reason: '$status');
      }
    });
  });

  group('OrderService.updateStatus', () {
    // Ditolak sebelum Firestore disentuh, jadi bisa dites tanpa Firebase
    test('status dibayar tidak boleh lewat updateStatus', () {
      expect(
        () => OrderService().updateStatus('o1', OrderStatus.paid),
        throwsArgumentError,
      );
    });
  });
}

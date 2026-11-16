import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/models/order.dart';
import 'package:food_order_app/models/payment_method.dart';
import 'package:food_order_app/screens/customer/payment_screen.dart';
import 'package:food_order_app/services/app_services.dart';
import 'package:food_order_app/services/auth_service.dart';
import 'package:food_order_app/services/chat_service.dart';
import 'package:food_order_app/services/order_service.dart';
import 'package:food_order_app/services/restaurant_service.dart';

// Pesanan terkonfirmasi untuk tes layar pembayaran
const _confirmedOrder = FoodOrder(
  id: 'o1',
  customerUid: 'c1',
  customerName: 'Rian',
  restaurantId: 'resto1',
  restaurantName: 'Mie Aceh Contoh',
  items: [OrderItem(menuItemId: 'mie', name: 'Mie Aceh', price: 15000, qty: 2)],
  total: 30000,
  status: OrderStatus.confirmed,
);

// Service asli; Firebase tidak disentuh selama tombol Bayar tidak ditekan
AppServices _services() => AppServices(
  auth: AuthService(),
  restaurants: RestaurantService(),
  orders: OrderService(),
  chat: ChatService(),
);

void main() {
  group('PaymentMethod', () {
    test('nama tersimpan dibaca kembali menjadi metode', () {
      for (final method in PaymentMethod.values) {
        expect(paymentMethodFromName(method.name), method);
      }
    });

    test('nama kosong atau tidak dikenal menjadi null', () {
      expect(paymentMethodFromName(null), isNull);
      expect(paymentMethodFromName('kartu_kredit'), isNull);
    });

    test('setiap metode punya label bahasa Indonesia', () {
      expect(PaymentMethod.ewallet.label, 'E-Wallet');
      expect(PaymentMethod.bankTransfer.label, 'Transfer Bank');
    });
  });

  group('PaymentScreen', () {
    testWidgets('tombol bayar nonaktif sampai metode dipilih', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(order: _confirmedOrder, services: _services()),
        ),
      );
      await tester.pumpAndSettle();

      final payButton = find.widgetWithText(FilledButton, 'Bayar Rp 30.000');
      expect(tester.widget<FilledButton>(payButton).onPressed, isNull);

      await tester.tap(find.text('E-Wallet'));
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(payButton).onPressed, isNotNull);
    });

    testWidgets('menampilkan penanda simulasi dan total', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(order: _confirmedOrder, services: _services()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Pembayaran simulasi'), findsOneWidget);
      expect(find.text('Rp 30.000'), findsOneWidget);
    });
  });
}

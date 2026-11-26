import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/models/order.dart';
import 'package:food_order_app/models/payment_method.dart';
import 'package:food_order_app/screens/customer/payment_screen.dart';
import 'package:food_order_app/services/app_services.dart';
import 'package:food_order_app/services/auth_service.dart';
import 'package:food_order_app/services/chat_service.dart';
import 'package:food_order_app/services/location_service.dart';
import 'package:food_order_app/services/order_service.dart';
import 'package:food_order_app/services/restaurant_service.dart';
import 'package:food_order_app/services/route_distance_service.dart';

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

class _FakeOrderService extends OrderService {
  @override
  Future<void> payOrder(String orderId, PaymentMethod method) async {}

  @override
  Future<void> chooseCodPayment(String orderId) async {}
}

AppServices _services({OrderService? orders}) => AppServices(
  auth: AuthService(),
  restaurants: RestaurantService(),
  orders: orders ?? OrderService(),
  chat: ChatService(),
  location: LocationService(),
  routeDistance: RouteDistanceService(),
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
      expect(PaymentMethod.cod.label, 'COD (Bayar di Tempat)');
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

      final payButton = find.widgetWithText(
        FilledButton,
        'Konfirmasi Bayar Rp 30.000',
      );
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

      expect(find.textContaining('Mode Simulasi Aman'), findsOneWidget);
      expect(find.text('Rp 30.000'), findsOneWidget);
    });

    testWidgets('menampilkan opsi COD', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(order: _confirmedOrder, services: _services()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COD (Bayar di Tempat)'), findsOneWidget);
      expect(find.text('Bayar tunai saat kurir tiba'), findsOneWidget);
    });

    testWidgets('struk lunas muncul setelah pembayaran sukses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(
            order: _confirmedOrder,
            services: _services(orders: _FakeOrderService()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('E-Wallet'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Konfirmasi Bayar Rp 30.000'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Struk Pembayaran'), findsOneWidget);
      expect(find.text('Pembayaran Sukses!'), findsOneWidget);
      expect(find.text('LUNAS'), findsNWidgets(2));
      expect(find.text('BELUM DIBAYAR'), findsOneWidget);
      expect(find.text('#o1'), findsOneWidget);
      expect(find.text('Mie Aceh Contoh'), findsOneWidget);
      expect(find.text('2x Mie Aceh'), findsOneWidget);
    });

    testWidgets('struk COD tidak menampilkan cap lunas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(
            order: _confirmedOrder,
            services: _services(orders: _FakeOrderService()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('COD (Bayar di Tempat)'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Pilih COD Rp 30.000'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Struk Pesanan'), findsOneWidget);
      expect(find.text('Metode COD Dipilih'), findsOneWidget);
      expect(
        find.text('Bayar tunai ke kurir saat pesanan tiba'),
        findsOneWidget,
      );
      expect(find.text('LUNAS'), findsNothing);
    });
  });
}

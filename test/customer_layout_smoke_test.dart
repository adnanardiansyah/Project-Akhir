import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_order_app/controllers/cart_controller.dart';
import 'package:food_order_app/models/app_user.dart';
import 'package:food_order_app/models/menu_item.dart';
import 'package:food_order_app/models/order.dart';
import 'package:food_order_app/models/restaurant.dart';
import 'package:food_order_app/screens/customer/cart_screen.dart';
import 'package:food_order_app/screens/customer/menu_screen.dart';
import 'package:food_order_app/screens/customer/my_orders_screen.dart';
import 'package:food_order_app/screens/customer/payment_screen.dart';
import 'package:food_order_app/screens/customer/restaurant_list_screen.dart';
import 'package:food_order_app/services/app_services.dart';
import 'package:food_order_app/services/auth_service.dart';
import 'package:food_order_app/services/chat_service.dart';
import 'package:food_order_app/services/location_service.dart';
import 'package:food_order_app/services/order_service.dart';
import 'package:food_order_app/services/restaurant_service.dart';
import 'package:food_order_app/services/route_distance_service.dart';

const _user = AppUser(
  uid: 'u1',
  role: UserRole.customer,
  displayName: ' pelanggan',
);
const _restaurant = Restaurant(
  id: 'r1',
  name: 'Rumah Makan Aceh Sedap',
  address: 'Jalan Sultan Agung Nomor 12, Lhokseumawe',
  location: GeoPoint(5.189, 97.14),
  ownerUid: 'owner1',
  reviewStatus: RestaurantReviewStatus.approved,
);
const _menuItem = MenuItem(
  id: 'm1',
  name: 'Mie Bangladesh Kuah Becek',
  price: 26000,
);
const _order = FoodOrder(
  id: 'o1',
  customerUid: 'u1',
  customerName: 'pelanggan',
  restaurantId: 'r1',
  restaurantName: 'Rumah Makan Aceh Sedap',
  items: [
    OrderItem(
      menuItemId: 'm1',
      name: 'Mie Bangladesh Kuah Becek',
      price: 26000,
      qty: 1,
    ),
  ],
  total: 26000,
  status: OrderStatus.confirmed,
);

class _FakeRestaurantService extends RestaurantService {
  @override
  Stream<List<Restaurant>> watchRestaurants() => Stream.value([_restaurant]);

  @override
  Stream<List<MenuItem>> watchMenuItems(String restaurantId) =>
      Stream.value([_menuItem]);
}

class _FakeOrderService extends OrderService {
  @override
  Stream<List<FoodOrder>> watchCustomerOrders(String customerUid) =>
      Stream.value([_order]);
}

class _FakeLocationService extends LocationService {
  @override
  Future<LocationResult> currentLocation() async =>
      const LocationResult.failure(LocationIssue.unavailable);

  @override
  Future<LocationResult> refreshCurrentLocation() async =>
      const LocationResult.failure(LocationIssue.unavailable);
}

AppServices _services() => AppServices(
  auth: AuthService(),
  restaurants: _FakeRestaurantService(),
  orders: _FakeOrderService(),
  chat: ChatService(),
  location: _FakeLocationService(),
  routeDistance: RouteDistanceService(),
);

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .single;
    view.physicalSize = const Size(320, 640);
    view.devicePixelRatio = 1;
  });

  testWidgets('beranda pelanggan tidak meluap pada layar sempit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RestaurantListScreen(
          user: _user,
          services: _services(),
          cart: CartController(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Restoran Pilihan di Lhokseumawe'), findsOneWidget);
  });

  testWidgets('halaman menu tidak meluap pada layar sempit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MenuScreen(
          restaurant: _restaurant,
          user: _user,
          services: _services(),
          cart: CartController(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daftar Menu Tersedia'), findsOneWidget);
  });

  testWidgets('keranjang tidak meluap pada layar sempit', (tester) async {
    final cart = CartController()..add(_restaurant, _menuItem);
    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(user: _user, services: _services(), cart: cart),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ringkasan Pembayaran'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ringkasan Pembayaran'), findsOneWidget);
  });

  testWidgets('daftar pesanan tidak meluap pada layar sempit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyOrdersScreen(user: _user, services: _services()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_restaurant.name), findsWidgets);
  });

  testWidgets('pembayaran tidak meluap pada layar sempit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentScreen(order: _order, services: _services()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('40.000'), findsNothing);
  });
}

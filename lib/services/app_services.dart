import 'auth_service.dart';
import 'chat_service.dart';
import 'order_service.dart';
import 'restaurant_service.dart';

// Wadah semua service agar cukup satu objek yang diteruskan ke layar
class AppServices {
  final AuthService auth;
  final RestaurantService restaurants;
  final OrderService orders;
  final ChatService chat;

  const AppServices({
    required this.auth,
    required this.restaurants,
    required this.orders,
    required this.chat,
  });
}

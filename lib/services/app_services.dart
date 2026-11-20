import 'auth_service.dart';
import 'chat_service.dart';
import 'location_service.dart';
import 'order_service.dart';
import 'restaurant_service.dart';
import 'route_distance_service.dart';

// Wadah semua service agar cukup satu objek yang diteruskan ke layar
class AppServices {
  final AuthService auth;
  final RestaurantService restaurants;
  final OrderService orders;
  final ChatService chat;
  final LocationService location;
  final RouteDistanceService routeDistance;

  const AppServices({
    required this.auth,
    required this.restaurants,
    required this.orders,
    required this.chat,
    required this.location,
    required this.routeDistance,
  });
}

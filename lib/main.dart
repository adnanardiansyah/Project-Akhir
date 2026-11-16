import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/order_service.dart';
import 'services/restaurant_service.dart';

// Titik masuk: inisialisasi Firebase lalu jalankan aplikasi
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    FoodOrderApp(
      services: AppServices(
        auth: AuthService(),
        restaurants: RestaurantService(),
        orders: OrderService(),
        chat: ChatService(),
      ),
    ),
  );
}

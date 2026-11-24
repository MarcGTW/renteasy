import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_api.dart';
import 'data/booking_repository.dart';
import 'data/http_booking_repository.dart';
import 'data/http_property_repository.dart';
import 'data/property_repository.dart';
import 'data/token_store.dart';
import 'models/booking_model.dart';
import 'models/property_model.dart';
import 'router.dart';

const apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8080',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null;

  router = buildRouter(initialLocation: loggedIn ? '/home' : '/login');

  void handleUnauthorized() => router.go('/login');

  final propertyRepository = HttpPropertyRepository(
    apiBase,
    tokens,
    onUnauthorized: handleUnauthorized,
  );
  final bookingRepository = HttpBookingRepository(
    apiBase,
    tokens,
    onUnauthorized: handleUnauthorized,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthApi>(
          create: (_) => AuthApi(apiBase, tokens),
        ),
        Provider<PropertyRepository>.value(value: propertyRepository),
        ChangeNotifierProvider(
          create: (_) {
            final model = PropertyModel(propertyRepository);
            if (loggedIn) model.load();
            return model;
          },
        ),
        Provider<BookingRepository>.value(value: bookingRepository),
        ChangeNotifierProvider(
          create: (_) {
            final model = BookingModel(bookingRepository);
            if (loggedIn) model.load();
            return model;
          },
        ),
      ],
      child: const RentEasyApp(),
    ),
  );
}

class RentEasyApp extends StatelessWidget {
  const RentEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RentEasy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}

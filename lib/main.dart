
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_property_repository.dart';
import 'data/property_repository.dart';
import 'data/mock_booking_repository.dart';
import 'data/booking_repository.dart';
import 'models/property_model.dart';
import 'models/booking_model.dart';
import 'router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<MockPropertyRepository>(
          create: (_) => MockPropertyRepository(),
        ),
        Provider<PropertyRepository>(
          create: (context) =>
              context.read<MockPropertyRepository>(),
        ),
        ChangeNotifierProvider(
          create: (context) => PropertyModel(
            context.read<PropertyRepository>(),
          )..load(),
        ),

        Provider<MockBookingRepository>(
          create: (_) => MockBookingRepository(),
        ),
        Provider<BookingRepository>(
          create: (context) =>
              context.read<MockBookingRepository>(),
        ),
        ChangeNotifierProvider(
          create: (context) => BookingModel(
            context.read<BookingRepository>(),
          )..load(),
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

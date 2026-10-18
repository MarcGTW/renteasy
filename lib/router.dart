
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/mock_data.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/details_screen.dart';
import 'screens/booking_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/properties',
      builder: (context, state) => const CatalogScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;

            final property = mockProperties
                .where((item) => item.id == id)
                .firstOrNull;

            if (property == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Объект недвижимости не найден'),
                ),
              );
            }

            return DetailsScreen(property: property);
          },
          routes: [
            GoRoute(
              path: 'book',
              builder: (context, state) {
                final id = state.pathParameters['id']!;

                final property = mockProperties
                    .where((item) => item.id == id)
                    .firstOrNull;

                if (property == null) {
                  return const Scaffold(
                    body: Center(
                      child: Text('Объект недвижимости не найден'),
                    ),
                  );
                }

                return BookingScreen(
                  propertyTitle: property.title,
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/bookings',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

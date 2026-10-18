
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
import 'widgets/app_shell.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    // Экран авторизации находится вне нижней панели
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),

    // Постоянная нижняя панель навигации
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Вкладка 1: Главная
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Вкладка 2: Каталог недвижимости
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/properties',
              builder: (context, state) => const CatalogScreen(),
              routes: [
                // Детальная информация о недвижимости
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
                    // Запись на просмотр
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
                              child: Text(
                                'Объект недвижимости не найден',
                              ),
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
          ],
        ),

        // Вкладка 3: Заявки
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookings',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),

        // Вкладка 4: Профиль
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

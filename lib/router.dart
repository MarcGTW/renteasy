
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/property_model.dart';
import 'screens/home_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/details_screen.dart';
import 'screens/booking_screen.dart';
import 'widgets/app_shell.dart';

late final GoRouter router;

GoRouter buildRouter({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/properties',
              builder: (context, state) => const CatalogScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return DetailsScreen(propertyId: id);
                  },
                  routes: [
                    GoRoute(
                      path: 'book',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        final property = context
                            .watch<PropertyModel>()
                            .byId(id);

                        final propertyModel =
                            context.watch<PropertyModel>();

                        if (propertyModel.isLoading) {
                          return const Scaffold(
                            body: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (propertyModel.error != null) {
                          return Scaffold(
                            body: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(propertyModel.error!),
                                  ElevatedButton(
                                    onPressed: () {
                                      context
                                          .read<PropertyModel>()
                                          .load();
                                    },
                                    child: const Text('Повторить'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookings',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),
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


import 'package:flutter/material.dart';
import 'router.dart';

void main() => runApp(const RentEasyApp());

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

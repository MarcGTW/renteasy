import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  final String propertyTitle;

  const BookingScreen({super.key, required this.propertyTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Запись на просмотр')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Объект: $propertyTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Ваше имя', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Номер телефона', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Удобная дата и время', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отправить заявку'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
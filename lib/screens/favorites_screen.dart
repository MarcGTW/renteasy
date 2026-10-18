import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/status_badge.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои просмотры и заявки')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: mockBookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = mockBookings[index];
          return Card(
            child: ListTile(
              title: Text(item.propertyTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item.id} • ${item.date} в ${item.time}'),
              trailing: StatusBadge(status: item.status),
            ),
          );
        },
      ),
    );
  }
}
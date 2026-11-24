
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking_model.dart';
import '../widgets/error_view.dart';
import '../widgets/status_badge.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои просмотры и заявки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить заявки',
            onPressed: () {
              context.read<BookingModel>().load();
            },
          ),
        ],
      ),
      body: Consumer<BookingModel>(
        builder: (context, model, child) {
          if (model.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (model.error != null) {
            return ErrorView(
              message: model.error!,
              onRetry: () {
                context.read<BookingModel>().load();
              },
            );
          }

          if (model.bookings.isEmpty) {
            return const Center(
              child: Text('Заявок пока нет'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: model.bookings.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = model.bookings[index];

              return Card(
                key: ValueKey(item.id),
                child: ListTile(
                  title: Text(
                    item.propertyTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${item.name} • ${item.phone}\n'
                    '${item.id} • ${item.date} в ${item.time}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(status: item.status),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Удалить заявку',
                        onPressed: () async {
                          final model = context.read<BookingModel>();
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await model.remove(item.id);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Заявка удалена'
                                    : (model.error ??
                                          'Не удалось удалить заявку'),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

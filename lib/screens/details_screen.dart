
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/property_model.dart';
import '../widgets/error_view.dart';

class DetailsScreen extends StatelessWidget {
  final String propertyId;

  const DetailsScreen({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    final propertyModel = context.watch<PropertyModel>();
    final property = propertyModel.byId(propertyId);

    if (propertyModel.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (propertyModel.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: ErrorView(
          message: propertyModel.error!,
          onRetry: () {
            context.read<PropertyModel>().load();
          },
        ),
      );
    }

    if (property == null) {
      return const Scaffold(
        body: Center(
          child: Text('Объект недвижимости не найден'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(property.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                child: Text(
                  property.imageInitials,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              property.address,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Тип сделки: ${property.type}'),
            Text('Количество комнат: ${property.rooms}'),
            Text('Площадь: ${property.area} м²'),
            Text('Рейтинг: ★ ${property.rating}'),
            const Divider(height: 24),
            Text('Риелтор: ${property.agentName}'),
            Text('Телефон: ${property.agentPhone}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  context.push('/properties/${property.id}/book');
                },
                child: const Text('Записаться на просмотр'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

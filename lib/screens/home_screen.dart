
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/property_model.dart';
import '../widgets/error_view.dart';
import '../widgets/property_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propertyModel = context.watch<PropertyModel>();
    final properties = propertyModel.properties;

    Widget recommendations;

    if (propertyModel.isLoading) {
      recommendations = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (propertyModel.error != null) {
      recommendations = ErrorView(
        message: propertyModel.error!,
        onRetry: () {
          context.read<PropertyModel>().load();
        },
      );
    } else if (properties.isEmpty) {
      recommendations = const Text(
        'Пока нет доступных объектов недвижимости',
      );
    } else {
      recommendations = Column(
        children: properties.take(3).map(
          (property) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: PropertyCard(
              property: property,
              onTap: () {
                context.push('/properties/${property.id}');
              },
            ),
          ),
        ).toList(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('RentEasy — Недвижимость'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.location_city, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Найдите идеальное жильё для аренды и покупки в Кишинёве',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Рекомендуемые объекты',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          recommendations,
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              context.push('/properties');
            },
            icon: const Icon(Icons.search),
            label: const Text('Посмотреть весь каталог'),
          ),
        ],
      ),
    );
  }
}

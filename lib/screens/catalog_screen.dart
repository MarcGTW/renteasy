
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/property_model.dart';
import '../widgets/error_view.dart';
import '../widgets/property_card.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propertyModel = context.watch<PropertyModel>();
    final properties = propertyModel.properties;

    Widget content;

    if (propertyModel.isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (propertyModel.error != null) {
      content = ErrorView(
        message: propertyModel.error!,
        onRetry: () {
          context.read<PropertyModel>().load();
        },
      );
    } else if (properties.isEmpty) {
      content = const Center(
        child: Text('Объекты недвижимости не найдены'),
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: properties.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = properties[index];

          return PropertyCard(
            key: ValueKey(item.id),
            property: item,
            onTap: () {
              context.push('/properties/${item.id}');
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог недвижимости'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить каталог',
            onPressed: () {
              context.read<PropertyModel>().load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по району, улице...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/property_model.dart';
import '../widgets/error_view.dart';
import '../widgets/property_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<PropertyModel>().search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String query) {
    context.read<PropertyModel>().load(search: query.trim());
  }

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
      final itemCount = properties.length + (propertyModel.hasMore ? 1 : 0);
      content = ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == properties.length) {
            context.read<PropertyModel>().loadMore();
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) => TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _applySearch,
                decoration: InputDecoration(
                  hintText: 'Поиск по району, улице...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Сбросить поиск',
                          onPressed: () {
                            _searchController.clear();
                            _applySearch('');
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

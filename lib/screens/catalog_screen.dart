import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/property_card.dart';
import 'details_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Каталог недвижимости')),
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
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: mockProperties.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = mockProperties[index];
                return PropertyCard(
                  property: item,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(property: item)));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
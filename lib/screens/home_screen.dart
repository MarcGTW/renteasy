import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/property_card.dart';
import 'details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RentEasy — Недвижимость')),
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
                      'Найдите идеальное жилье для аренды и покупки в Кишинёве',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Рекомендуемые объекты', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...mockProperties.take(3).map((property) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: PropertyCard(
                  property: property,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(property: property)));
                  },
                ),
              )),
        ],
      ),
    );
  }
}
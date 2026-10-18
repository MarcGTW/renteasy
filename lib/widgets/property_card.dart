import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRent = property.type == 'Аренда';

    return Card(
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(property.imageInitials),
        ),
        title: Text(property.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${property.address}\n${property.rooms} комн. • ${property.area} м²'),
        isThreeLine: true,
        trailing: Text(
          isRent ? '€${property.price.toStringAsFixed(0)}/мес' : '€${property.price.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
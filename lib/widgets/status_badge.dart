import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Подтверждено':
      case 'Аренда':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'В ожидании':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case 'Завершено':
      case 'Продажа':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        break;
      default:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
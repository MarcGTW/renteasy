import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(radius: 40, child: Icon(Icons.person, size: 50)),
          SizedBox(height: 12),
          Center(child: Text('Марк Паскари', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Center(child: Text('+373 69 000000')),
          Divider(height: 32),
          ListTile(leading: Icon(Icons.apartment), title: Text('Мои объявления')),
          ListTile(leading: Icon(Icons.history), title: Text('История поисков')),
          ListTile(leading: Icon(Icons.settings), title: Text('Настройки уведомлений')),
        ],
      ),
    );
  }
}
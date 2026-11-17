
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_property_repository.dart';
import '../data/mock_booking_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _simulateError = false;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Вы действительно хотите выйти из RentEasy?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx, false);
            },
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx, true);
            },
            child: const Text('Да, выйти'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Марк Паскари',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Center(
            child: Text('+373 69 000000'),
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.apartment),
            title: Text('Мои объявления'),
          ),
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('История поисков'),
          ),
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('Настройки уведомлений'),
          ),
          const Divider(height: 32),

          SwitchListTile(
            secondary: const Icon(Icons.wifi_off),
            title: const Text('Симулировать сбой сети'),
            subtitle: const Text(
              'Включите, чтобы проверить обработку ошибок',
            ),
            value: _simulateError,
            onChanged: (value) {
  setState(() {
    _simulateError = value;
  });

  context.read<MockPropertyRepository>().simulateError = value;
  context.read<MockBookingRepository>().simulateError = value;
},
          ),

          const Divider(height: 32),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              'Выйти из аккаунта',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

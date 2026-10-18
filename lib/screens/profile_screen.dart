
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

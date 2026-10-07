import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Даниил Пятков',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Студент',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('Email'),
                  subtitle: Text('student@example.com'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.school_outlined),
                  title: Text('Специальность'),
                  subtitle: Text('Информационные технологии'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.calendar_month_outlined),
                  title: Text('Курс обучения'),
                  subtitle: Text('3 курс'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Уведомления'),
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Тёмная тема'),
                  trailing: Switch(
                    value: false,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}
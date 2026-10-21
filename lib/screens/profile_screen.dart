import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_task_repository.dart';
import '../models/task_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Локальное состояние переключателя.
  bool _simulateNetworkError = false;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Выход из аккаунта'),
          content: const Text(
            'Вы действительно хотите выйти?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    if (ok == true && context.mounted) {
      context.go('/login');
    }
  }

  void _toggleNetworkError(bool value) {
    setState(() {
      _simulateNetworkError = value;
    });

    // Включаем или выключаем имитацию сбоя.
    context.read<MockTaskRepository>().simulateError = value;

    // Сразу проверяем результат на экране заданий.
    context.read<TaskModel>().load();
  }

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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wifi_off_outlined),
                  title: const Text('Симулировать сбой сети'),
                  subtitle: const Text(
                    'Проверка обработки ошибок загрузки',
                  ),
                  trailing: Switch(
                    value: _simulateNetworkError,
                    onChanged: _toggleNetworkError,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}
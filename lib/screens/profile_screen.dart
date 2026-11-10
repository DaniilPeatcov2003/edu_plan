import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'edit_profile_screen.dart';
import '../services/auth_service.dart';
import '../models/theme_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Загружаем данные текущего пользователя с backend.
  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final profile = await context.read<AuthService>().getMe();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
        _profileError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profileError = e.toString();
        _isLoadingProfile = false;
      });
    }
  }

  // Редактирование профиля.
  Future<void> _editProfile() async {
    if (_profile == null) return;

    final updatedProfile = await Navigator.of(context).push<
        Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: _profile!),
      ),
    );

    if (!mounted || updatedProfile == null) return;

    setState(() {
      _profile = updatedProfile;
    });
  }

  // Выход из аккаунта.
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
      await context.read<AuthService>().logout();

      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  // Удаление аккаунта.
  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Удалить аккаунт?'),
          content: const Text(
            'Это действие необратимо. '
            'Ваш профиль, задания, заметки и загруженные файлы будут удалены.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AuthService>().deleteAccount();

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось удалить аккаунт: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final name = _profile?['name']?.toString() ?? 'Пользователь';
    final email = _profile?['email']?.toString() ?? '';
    final specialty = _profile?['specialty']?.toString() ?? 'Не указана';
    final studyYear = _profile?['studyYear']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            onPressed: _profile == null ? null : _editProfile,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Редактировать профиль',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isLoadingProfile)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_profileError != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Не удалось загрузить профиль',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _profileError!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _loadProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
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
                      name,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Студент',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('Специальность'),
                    subtitle: Text(specialty),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Курс обучения'),
                    subtitle: Text(
                      studyYear == null
                          ? 'Не указан'
                          : '$studyYear курс',
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Настройки приложения.
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
                Consumer<ThemeModel>(
                  builder: (context, themeModel, child) {
                    return ListTile(
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Тёмная тема'),
                      trailing: Switch(
                        value: themeModel.isDarkMode,
                        onChanged: (value) {
                          themeModel.setDarkMode(value);
                        },
                      ),
                    );
                  },
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

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _profile == null
                ? null
                : () => _deleteAccount(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Удалить аккаунт'),
          ),
        ],
      ),
    );
  }
}
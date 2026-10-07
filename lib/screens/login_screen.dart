import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.school,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),

                Text(
                  'EduPlan',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: 8),

                Text(
                  'Планируйте учёбу и следите за заданиями',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: 32),

                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'student@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationScreen(),
                      ),
                    );
                  },
                  child: const Text('Войти'),
                ),

                const SizedBox(height: 8),

                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Создать аккаунт'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class TaskFormScreen extends StatelessWidget {
  const TaskFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое задание'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Название задания',
                hintText: 'Например, разработать UI',
                prefixIcon: const Icon(Icons.assignment_outlined),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownMenu<String>(
              width: double.infinity,
              label: const Text('Курс'),
              leadingIcon: const Icon(Icons.school_outlined),
              dropdownMenuEntries: mockCourses
                  .map(
                    (course) => DropdownMenuEntry<String>(
                      value: course.name,
                      label: course.name,
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                labelText: 'Дедлайн',
                hintText: 'ДД.ММ.ГГГГ',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownMenu<String>(
              width: double.infinity,
              label: const Text('Приоритет'),
              leadingIcon: const Icon(Icons.flag_outlined),
              dropdownMenuEntries: const [
                DropdownMenuEntry(
                  value: 'Низкий',
                  label: 'Низкий',
                ),
                DropdownMenuEntry(
                  value: 'Средний',
                  label: 'Средний',
                ),
                DropdownMenuEntry(
                  value: 'Высокий',
                  label: 'Высокий',
                ),
              ],
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save_outlined),
              label: const Text('Сохранить задание'),
            ),

            const SizedBox(height: 8),

            OutlinedButton(
              onPressed: () {},
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }
}
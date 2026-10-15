
import 'package:flutter/material.dart';

import '../data/mock_data.dart';

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({
    super.key,
    required this.id,
  });

  final String id;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final matchingCourses = mockCourses.where(
      (course) => course.id == id,
    );

    if (matchingCourses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Информация о курсе'),
        ),
        body: const Center(
          child: Text('Курс не найден'),
        ),
      );
    }

    final course = matchingCourses.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Информация о курсе'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.school,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      course.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.teacher,
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
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('День'),
                    subtitle: Text(course.day),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Время'),
                    subtitle: Text(course.time),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.room),
                    title: const Text('Аудитория'),
                    subtitle: Text(course.room),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.school_outlined),
                    title: Text('Формат'),
                    subtitle: Text('Очное занятие'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'О курсе',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Курс предназначен для изучения принципов '
                      'разработки мобильных приложений, создания '
                      'пользовательского интерфейса и работы с Flutter.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


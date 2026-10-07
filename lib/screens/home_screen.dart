import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/task_card.dart';
import '../widgets/course_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduPlan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Добро пожаловать!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 4),

          Text(
            'Планируйте учебный день и не забывайте о заданиях.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const SizedBox(height: 24),

          Text(
            'Ближайшее занятие',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          CourseCard(
            course: mockCourses[0],
          ),

          const SizedBox(height: 24),

          Text(
            'Ближайшие задания',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          ...mockTasks.take(3).map(
                (task) => TaskCard(
                  task: task,
                ),
              ),
        ],
      ),
    );
  }
}
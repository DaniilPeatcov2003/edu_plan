import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/course_model.dart';
import '../models/task_model.dart';
import '../widgets/course_card.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Загружаем данные после открытия главной страницы.
    context.read<CourseModel>().load();
    context.read<TaskModel>().load();
  }

  // Поиск ближайшего занятия.
  Course? _findNextCourse(List<Course> courses) {
    final now = DateTime.now();

    const weekdays = {
      'Понедельник': DateTime.monday,
      'Вторник': DateTime.tuesday,
      'Среда': DateTime.wednesday,
      'Четверг': DateTime.thursday,
      'Пятница': DateTime.friday,
      'Суббота': DateTime.saturday,
      'Воскресенье': DateTime.sunday,
    };

    DateTime? nearestDate;
    Course? nearestCourse;
    CourseSession? nearestSession;

    for (final course in courses) {
      for (final session in course.sessions) {
        final weekday = weekdays[session.day.trim()];

        // Поддерживаем форматы 10.00 и 10:00.
        final timeParts = session.time.trim().split(RegExp(r'[:.]'));

        if (weekday == null || timeParts.length != 2) {
          continue;
        }

        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);

        if (hour == null ||
            minute == null ||
            hour < 0 ||
            hour > 23 ||
            minute < 0 ||
            minute > 59) {
          continue;
        }

        final daysAhead = (weekday - now.weekday + 7) % 7;

        var sessionDate = DateTime(
          now.year,
          now.month,
          now.day + daysAhead,
          hour,
          minute,
        );

        // Если занятие на сегодня уже началось или прошло,
        // ищем его на следующей неделе.
        if (!sessionDate.isAfter(now)) {
          sessionDate = sessionDate.add(const Duration(days: 7));
        }

        if (nearestDate == null || sessionDate.isBefore(nearestDate)) {
          nearestDate = sessionDate;
          nearestCourse = course;
          nearestSession = session;
        }
      }
    }

    if (nearestCourse == null || nearestSession == null) {
      return null;
    }

    return Course(
      id: nearestCourse.id,
      name: nearestCourse.name,
      teacher: nearestCourse.teacher,
      sessions: [nearestSession],
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskModel = context.watch<TaskModel>();
    final courseModel = context.watch<CourseModel>();

    final nextCourse = _findNextCourse(courseModel.courses);

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

          if (courseModel.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (courseModel.errorMessage != null)
            Column(
              children: [
                Text(courseModel.errorMessage!),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => courseModel.load(),
                  child: const Text('Повторить'),
                ),
              ],
            )
          else if (nextCourse == null)
            const Text('Занятий пока нет.')
          else
            CourseCard(course: nextCourse),

          const SizedBox(height: 24),

          Text(
            'Ближайшие задания',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          if (taskModel.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (taskModel.errorMessage != null)
            Column(
              children: [
                Text(taskModel.errorMessage!),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => taskModel.load(),
                  child: const Text('Повторить'),
                ),
              ],
            )
          else if (taskModel.tasks.isEmpty)
            const Text('Заданий пока нет.')
          else
            ...taskModel.tasks.take(3).map(
                  (task) => TaskCard(task: task),
                ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const List<String> _days = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
      ),
      body: Consumer<CourseModel>(
        builder: (context, courseModel, child) {
          final courses = courseModel.courses;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final day in _days)
                _buildDaySection(day, courses),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDaySection(String day, List courses) {
    final sessions = courses.expand((course) {
      return course.sessions
          .where((session) => session.day == day)
          .map((session) => (course: course, session: session));
    }).toList();

    sessions.sort(
      (a, b) => a.session.time.compareTo(b.session.time),
    );

    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...sessions.map((item) => Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(item.course.name),
                  subtitle: Text(
                    '${item.session.time} • '
                    'Аудитория ${item.session.room}\n'
                    '${item.course.teacher}',
                  ),
                  isThreeLine: true,
                ),
              )),
        ],
      ),
    );
  }
}

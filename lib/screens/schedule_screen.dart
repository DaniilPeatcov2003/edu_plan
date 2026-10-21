import 'package:flutter/material.dart';
import '../data/mock_courses.dart';
import '../widgets/course_card.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockCourses.length,
        itemBuilder: (context, index) {
          final course = mockCourses[index];

          return CourseCard(
            course: course,
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/course.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
  });

  final Course course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            course.name.isNotEmpty ? course.name[0] : '?',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(course.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.teacher),
            const SizedBox(height: 8),
            ...course.sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${session.day} • ${session.time} • '
                  'Аудитория ${session.room}',
                ),
              ),
            ),
          ],
        ),
        isThreeLine: course.sessions.length == 1,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
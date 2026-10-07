import 'package:flutter/material.dart';
import '../data/mock_data.dart';

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
            course.name[0],
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(course.name),
        subtitle: Text(
          '${course.teacher}\n'
          '${course.day} • ${course.time} • '
          'Аудитория ${course.room}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
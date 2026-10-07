import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  final Task task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Icon(
            task.status == 'Завершено'
                ? Icons.check
                : Icons.assignment_outlined,
          ),
        ),
        title: Text(task.title),
        subtitle: Text(
          '${task.course}\n'
          'Срок: ${task.deadline} • '
          'Приоритет: ${task.priority}',
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(task.status),
        ),
      ),
    );
  }
}
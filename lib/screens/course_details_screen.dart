
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/course.dart';
import '../models/course_model.dart';

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({
    super.key,
    required this.id,
  });

  final String id;

  Future<void> _deleteCourse(
    BuildContext context,
    CourseModel courseModel,
    Course course,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удалить курс?'),
          content: Text(
            'Вы действительно хотите удалить курс "${course.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final error = await courseModel.deleteCourse(course);

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    await context.read<TaskModel>().load();

    if (!context.mounted) return;

    context.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Курс и связанные задания удалены')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<CourseModel>(
      builder: (context, courseModel, child) {
        if (courseModel.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Информация о курсе'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final course = courseModel.byId(id);

        if (course == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Информация о курсе'),
            ),
            body: Center(
              child: courseModel.errorMessage != null
                  ? Text(courseModel.errorMessage!)
                  : const Text('Курс не найден'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Информация о курсе'),
            actions: [
              IconButton(
                onPressed: () {
                  context.push('/courses/${course.id}/edit');
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Редактировать курс',
              ),
              IconButton(
                onPressed: () {
                  _deleteCourse(context, courseModel, course);
                },
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Удалить курс',
              ),
            ],
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Расписание занятий',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),

                        ...course.sessions.map((session) {
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.calendar_today),
                                title: Text(session.day),
                                subtitle: Text(
                                  '${session.time} • '
                                  'Аудитория ${session.room}',
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.school_outlined),
                                title: const Text('Формат'),
                                subtitle: Text(
                                  session.format == 'Заочное'
                                      ? 'Заочное занятие'
                                      : 'Очное занятие',
                                ),
                              ),
                              if (session != course.sessions.last)
                                const Divider(),
                            ],
                          );
                        }),
                      ],
                    ),
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
      },
    );
  }
}

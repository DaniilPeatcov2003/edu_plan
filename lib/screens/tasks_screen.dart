import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Подписываем экран на изменения модели.
    final model = context.watch<TaskModel>();
    final tasks = model.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задания'),
      ),

      // Отображаем состояние модели.
      body: model.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : model.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          model.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            context.read<TaskModel>().load();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 56,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          FilterChip(
                            label: const Text('Все'),
                            selected: true,
                            onSelected: (_) {},
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Не начато'),
                            selected: false,
                            onSelected: (_) {},
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('В процессе'),
                            selected: false,
                            onSelected: (_) {},
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Завершено'),
                            selected: false,
                            onSelected: (_) {},
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: tasks.isEmpty
                          ? const Center(
                              child: Text('Заданий пока нет'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: tasks.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return TaskCard(
                                  task: task,

                                  // Открываем форму редактирования по ID задания.
                                  onEdit: () {
                                    context.push('/tasks/${task.id}/edit');
                                  },

                                  // Удаляем задание только после подтверждения.
                                  onDelete: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Удалить задание?'),
                                        content: Text(
                                          'Задание «${task.title}» будет удалено.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(dialogContext, false);
                                            },
                                            child: const Text('Отмена'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              Navigator.pop(dialogContext, true);
                                            },
                                            child: const Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed != true || !context.mounted) return;

                                    final error = await context
                                        .read<TaskModel>()
                                        .deleteTask(task);

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error ?? 'Задание удалено'),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),

      // Кнопка создания доступна, когда данные загружены.
      floatingActionButton:
          model.isLoading || model.errorMessage != null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    context.push('/tasks/new');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Создать задание'),
                ),
    );
  }
}
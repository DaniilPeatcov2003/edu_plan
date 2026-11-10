
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaskModel>().load();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TaskModel>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () {
        if (!mounted) return;
        context.read<TaskModel>().load(search: value);
      },
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    context.read<TaskModel>().load(search: '');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TaskModel>();
    final tasks = model.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задания'),
      ),
      body: model.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : model.errorMessage != null && tasks.isEmpty
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
                            model.load(
                              search: _searchController.text,
                            );
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск задания',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),

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
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: tasks.length +
                                  (model.isLoadingMore ||
                                          model.errorMessage != null
                                      ? 1
                                      : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index >= tasks.length) {
                                  if (model.isLoadingMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  return Center(
                                    child: TextButton.icon(
                                      onPressed: () => model.loadMore(),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Повторить загрузку'),
                                    ),
                                  );
                                }

                                final task = tasks[index];

                                return TaskCard(
                                  task: task,
                                  onStatusChanged: (newStatus) async {
                                    final updatedTask = task.copyWith(
                                      status: newStatus,
                                    );

                                    final error = await context.read<TaskModel>().updateTask(
                                      task,
                                      updatedTask,
                                    );

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error ?? 'Статус задания изменён',
                                        ),
                                      ),
                                    );
                                  },
                                  onEdit: () {
                                    context.push('/tasks/${task.id}/edit');
                                  },
                                  onDelete: () async {
                                    final confirmed =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) =>
                                          AlertDialog(
                                        title: const Text('Удалить задание?'),
                                        content: Text(
                                          'Задание «${task.title}» будет удалено.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                dialogContext,
                                                false,
                                              );
                                            },
                                            child: const Text('Отмена'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                dialogContext,
                                                true,
                                              );
                                            },
                                            child: const Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed != true ||
                                        !context.mounted) {
                                      return;
                                    }

                                    final error = await context
                                        .read<TaskModel>()
                                        .deleteTask(task);

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error ?? 'Задание удалено',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),

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

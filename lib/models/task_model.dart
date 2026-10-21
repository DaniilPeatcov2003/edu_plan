import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/task_repository.dart';
import 'task.dart';

class TaskModel extends ChangeNotifier {
  TaskModel({required this.repository});

  final TaskRepository repository;
  final List<Task> _tasks = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Экран может читать список, но не изменять его напрямую.
  List<Task> get tasks => List.unmodifiable(_tasks);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Загружаем задания из репозитория.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.fetchAll();

    if (result is Ok<List<Task>>) {
      _tasks
        ..clear()
        ..addAll(result.value);
    } else if (result is Err<List<Task>>) {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Создаём задание.
  Future<String?> addTask(Task task) async {
    final result = await repository.create(task);

    if (result is Ok<Task>) {
      _tasks.add(result.value);
      notifyListeners();
      return null;
    }

    return (result as Err<Task>).message;
  }

  // Изменяем задание.
  Future<String?> updateTask(
    Task oldTask,
    Task updatedTask,
  ) async {
    final result = await repository.update(oldTask, updatedTask);

    if (result is Ok<Task>) {
      final index = _tasks.indexOf(oldTask);

      if (index != -1) {
        _tasks[index] = result.value;
        notifyListeners();
      }

      return null;
    }

    return (result as Err<Task>).message;
  }

  // Удаляем задание.
  Future<String?> deleteTask(Task task) async {
    final result = await repository.delete(task);

    if (result is Ok<void>) {
      _tasks.remove(task);
      notifyListeners();
      return null;
    }

    return (result as Err<void>).message;
  }
}
import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/task_repository.dart';
import 'task.dart';

class TaskModel extends ChangeNotifier {
  TaskModel({required this.repository});

  final TaskRepository repository;
  final List<Task> _tasks = [];

  static const int pageSize = 20;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  String? _errorMessage;
  String _search = '';
  int _currentPage = 0;

  Task? byId(String id) {
    for (final task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }

    return null;
  }

  List<Task> get tasks => List.unmodifiable(_tasks);

  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  bool get hasMore => _hasMore;

  String? get errorMessage => _errorMessage;

  // Загрузка первой страницы.
  Future<void> load({String? search}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _search = search ?? _search;
    _currentPage = 0;
    _hasMore = true;

    _tasks.clear();
    notifyListeners();

    final result = await repository.fetchAll(
      page: 1,
      limit: pageSize,
      search: _search,
    );

    if (result is Ok<List<Task>>) {
      _tasks.addAll(result.value);
      _currentPage = 1;
      _hasMore = result.value.length == pageSize;
    } else if (result is Err<List<Task>>) {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Загрузка следующей страницы.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;

    final result = await repository.fetchAll(
      page: nextPage,
      limit: pageSize,
      search: _search,
    );

    if (result is Ok<List<Task>>) {
      _tasks.addAll(result.value);
      _currentPage = nextPage;
      _hasMore = result.value.length == pageSize;
    } else if (result is Err<List<Task>>) {
      _errorMessage = result.message;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // Создание задания.
  Future<Result<Task>> addTask(Task task) async {
    final result = await repository.create(task);

    if (result is Ok<Task>) {
      await load(search: _search);
    }

    return result;
  }

  // Изменение задания.
  Future<String?> updateTask(
    Task oldTask,
    Task updatedTask,
  ) async {
    final result = await repository.update(oldTask, updatedTask);

    if (result is Ok<Task>) {
      final index = _tasks.indexWhere(
        (item) => item.id == oldTask.id,
      );

      if (index != -1) {
        _tasks[index] = result.value;
        notifyListeners();
      }

      return null;
    }

    return (result as Err<Task>).message;
  }

  // Удаление задания.
  Future<String?> deleteTask(Task task) async {
    final result = await repository.delete(task);

    if (result is Ok<void>) {
      _tasks.removeWhere((item) => item.id == task.id);
      notifyListeners();
      return null;
    }

    return (result as Err<void>).message;
  }
}

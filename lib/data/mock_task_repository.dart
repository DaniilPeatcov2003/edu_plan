import '../models/task.dart';
import 'mock_data.dart' show mockTasks;
import 'result.dart';
import 'task_repository.dart';

class MockTaskRepository implements TaskRepository {
  MockTaskRepository() : _tasks = List.of(mockTasks);

  // Временное хранилище заданий в памяти.
  final List<Task> _tasks;

  // Если true, операции будут возвращать ошибку.
  bool simulateError = false;

  // Имитируем задержку ответа сервера.
  static const Duration _delay = Duration(milliseconds: 700);

  @override
  Future<Result<List<Task>>> fetchAll() async {
    await Future.delayed(_delay);

    if (simulateError) {
      return const Err<List<Task>>('Ошибка загрузки заданий');
    }

    return Ok<List<Task>>(List.unmodifiable(_tasks));
  }

  @override
  Future<Result<Task>> create(Task task) async {
    await Future.delayed(_delay);

    if (simulateError) {
      return const Err<Task>('Не удалось создать задание');
    }

    // ID назначается репозиторием, а не экраном формы.
    final createdTask = Task(
      id: 'task-${DateTime.now().microsecondsSinceEpoch}',
      title: task.title,
      course: task.course,
      deadline: task.deadline,
      status: task.status,
      priority: task.priority,
    );

    _tasks.add(createdTask);
    return Ok<Task>(createdTask);
  }

  @override
  Future<Result<Task>> update(Task oldTask, Task updatedTask) async {
    await Future.delayed(_delay);

    if (simulateError) {
      return const Err<Task>('Не удалось обновить задание');
    }

    final index = _tasks.indexOf(oldTask);

    if (index == -1) {
      return const Err<Task>('Задание не найдено');
    }

    _tasks[index] = updatedTask;
    return Ok<Task>(updatedTask);
  }

  @override
  Future<Result<void>> delete(Task task) async {
    await Future.delayed(_delay);

    if (simulateError) {
      return const Err<void>('Не удалось удалить задание');
    }

    final index = _tasks.indexOf(task);

    if (index == -1) {
      return const Err<void>('Задание не найдено');
    }

    _tasks.removeAt(index);
    return const Ok<void>(null);
  }

  @override
  Future<Result<Task>> fetchById(String id) async {
    await Future.delayed(_delay);

    if (simulateError) {
      return const Err<Task>('Ошибка загрузки задания');
    }

    for (final task in _tasks) {
      if (task.id == id) {
        return Ok<Task>(task);
      }
    }

    return const Err<Task>('Задание не найдено');
  }
}

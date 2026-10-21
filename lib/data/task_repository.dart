import '../models/task.dart';
import 'result.dart';

abstract interface class TaskRepository {
  // Получить список всех заданий.
  Future<Result<List<Task>>> fetchAll();

  // Получить задание по ID.
  Future<Result<Task>> fetchById(String id);

  // Создать задание.
  Future<Result<Task>> create(Task task);

  // Изменить существующее задание.
  Future<Result<Task>> update(
    Task oldTask,
    Task updatedTask,
  );

  // Удалить задание.
  Future<Result<void>> delete(Task task);
}
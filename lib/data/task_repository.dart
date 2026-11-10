
import '../models/task.dart';
import 'result.dart';

abstract interface class TaskRepository {
  // Получить страницу заданий с возможностью поиска.
  Future<Result<List<Task>>> fetchAll({
    int page = 1,
    int limit = 20,
    String search = '',
  });

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

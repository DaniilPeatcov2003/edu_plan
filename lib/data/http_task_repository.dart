
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task.dart';
import '../services/auth_service.dart';
import 'result.dart';
import 'task_repository.dart';

class HttpTaskRepository implements TaskRepository {
  HttpTaskRepository({required this.authService});

  final AuthService authService;

  static const String _baseUrl = 'http://10.0.2.2:8080';

  // Заголовки с JWT-токеном.
  Future<Map<String, String>> _headers() async {
    final token = await authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Необходимо войти в аккаунт');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Получение сообщения об ошибке от сервера.
  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        final error = data['error'];

        if (error is Map) {
          return (error['message'] ??
                  error['code'] ??
                  'Ошибка сервера: ${response.statusCode}')
              .toString();
        }

        return (data['message'] ??
                error ??
                data['code'] ??
                'Ошибка сервера: ${response.statusCode}')
            .toString();
      }
    } catch (_) {
      // Если ответ не является JSON.
    }

    return 'Ошибка сервера: ${response.statusCode}';
  }

  // Преобразование JSON в объект Task.
  Task _taskFromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      title: json['title'] as String,
      course: json['course'] as String,
      courseId: json['courseId']?.toString(),
      deadline: json['deadline'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
    );
  }

  // Преобразование Task в JSON для отправки серверу.
  Map<String, dynamic> _taskToJson(Task task) {
    return {
      'title': task.title,
      'course': task.course,
      'courseId': task.courseId == null
          ? null
          : int.tryParse(task.courseId!),
      'deadline': task.deadline,
      'status': task.status,
      'priority': task.priority,
    };
  }

  @override
  Future<Result<List<Task>>> fetchAll({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/tasks').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'search': search,
        },
      );

      final response = await http.get(
        uri,
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return Err<List<Task>>(_errorMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List;

      final tasks = items
          .map((item) => _taskFromJson(item as Map<String, dynamic>))
          .toList();

      return Ok<List<Task>>(tasks);
    } catch (e) {
      return Err<List<Task>>('Ошибка загрузки заданий: $e');
    }
  }

  @override
  Future<Result<Task>> fetchById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return Err<Task>(_errorMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return Ok<Task>(_taskFromJson(data));
    } catch (e) {
      return Err<Task>('Ошибка загрузки задания: $e');
    }
  }

  @override
  Future<Result<Task>> create(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: await _headers(),
        body: jsonEncode(_taskToJson(task)),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        return Err<Task>(_errorMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return Ok<Task>(_taskFromJson(data));
    } catch (e) {
      return Err<Task>('Не удалось создать задание: $e');
    }
  }

  @override
  Future<Result<Task>> update(
    Task oldTask,
    Task updatedTask,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/${oldTask.id}'),
        headers: await _headers(),
        body: jsonEncode(_taskToJson(updatedTask)),
      );

      if (response.statusCode != 200) {
        return Err<Task>(_errorMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return Ok<Task>(_taskFromJson(data));
    } catch (e) {
      return Err<Task>('Не удалось обновить задание: $e');
    }
  }

  @override
  Future<Result<void>> delete(Task task) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tasks/${task.id}'),
        headers: await _headers(),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        return Err<void>(_errorMessage(response));
      }

      return const Ok<void>(null);
    } catch (e) {
      return Err<void>('Не удалось удалить задание: $e');
    }
  }
}

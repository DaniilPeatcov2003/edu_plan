import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course.dart';
import '../models/course_page.dart';
import '../services/auth_service.dart';
import 'course_repository.dart';
import 'result.dart';

class HttpCourseRepository implements CourseRepository {
  HttpCourseRepository({required this.authService});

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

  // Получение сообщения об ошибке.
  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        return (data['message'] ??
                data['error'] ??
                data['code'] ??
                'Ошибка сервера: ${response.statusCode}')
            .toString();
      }
    } catch (_) {
      // Ответ не является JSON.
    }

    return 'Ошибка сервера: ${response.statusCode}';
  }

  // Преобразование JSON в Course.
  Course _courseFromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'];

    final sessions = rawSessions is List && rawSessions.isNotEmpty
        ? rawSessions.map((item) {
            final session = item as Map<String, dynamic>;

            return CourseSession(
              id: session['id'].toString(),
              day: session['day'] as String,
              time: session['time'] as String,
              room: session['room'] as String,
              format: session['format'] as String? ?? 'Очное',
            );
          }).toList()
        : [
            CourseSession(
              id: '${json['id']}-1',
              day: json['day'] as String,
              time: json['time'] as String,
              room: json['room'] as String,
              format: json['format'] as String? ?? 'Очное',
            ),
          ];

    return Course(
      id: json['id'].toString(),
      name: json['name'] as String,
      teacher: json['teacher'] as String,
      sessions: sessions,
    );
  }

  // Преобразование Course в JSON.
  Map<String, dynamic> _courseToJson(Course course) {
    return {
      'name': course.name,
      'teacher': course.teacher,
      'sessions': course.sessions
          .map((session) => {
                'day': session.day,
                'time': session.time,
                'room': session.room,
                'format': session.format,
              })
          .toList(),
      'day': course.day,
      'time': course.time,
      'room': course.room,
    };
  }

  @override
  Future<Result<CoursePage>> fetchAll({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/courses').replace(
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
        return Err<CoursePage>(_errorMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final courses = (data['items'] as List)
          .map(
            (item) => _courseFromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      return Ok<CoursePage>(
        CoursePage(
          items: courses,
          page: data['page'] as int,
          limit: data['limit'] as int,
          total: data['total'] as int,
        ),
      );
    } catch (e) {
      return Err<CoursePage>('Ошибка загрузки курсов: $e');
    }
  }

  @override
  Future<Result<Course>> fetchById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses/$id'),
        headers: await _headers(),
      );

      if (response.statusCode != 200) {
        return Err<Course>(_errorMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return Ok<Course>(_courseFromJson(data));
    } catch (e) {
      return Err<Course>('Ошибка загрузки курса: $e');
    }
  }

  @override
  Future<Result<Course>> create(Course course) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courses'),
        headers: await _headers(),
        body: jsonEncode(_courseToJson(course)),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        return Err<Course>(_errorMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return Ok<Course>(_courseFromJson(data));
    } catch (e) {
      return Err<Course>('Не удалось создать курс: $e');
    }
  }

  @override
  Future<Result<Course>> update(
    Course oldCourse,
    Course updatedCourse,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/courses/${oldCourse.id}'),
        headers: await _headers(),
        body: jsonEncode(_courseToJson(updatedCourse)),
      );

      if (response.statusCode != 200) {
        return Err<Course>(_errorMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return Ok<Course>(_courseFromJson(data));
    } catch (e) {
      return Err<Course>('Не удалось обновить курс: $e');
    }
  }

  @override
  Future<Result<void>> delete(Course course) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/courses/${course.id}'),
        headers: await _headers(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        return Err<void>(_errorMessage(response));
      }

      return const Ok<void>(null);
    } catch (e) {
      return Err<void>('Не удалось удалить курс: $e');
    }
  }
}


import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:8080';
  static const String _tokenKey = 'auth_token';

  // Вход в аккаунт.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    await _saveToken(response, isLogin: true);
  }

  // Регистрация нового аккаунта.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String specialty,
    required int studyYear,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'specialty': specialty,
        'studyYear': studyYear,
      }),
    );

    await _saveToken(response);
  }

  // Преобразуем технические ошибки в понятные сообщения.
  String _friendlyError(http.Response response, {bool isLogin = false}) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        final error = data['error'];

        final code = error is Map
            ? error['code']?.toString()
            : data['code']?.toString();

        switch (code) {
          case 'UNAUTHORIZED':
            return isLogin
                ? 'Неверный e-mail или пароль'
                : 'Необходимо войти в аккаунт';

          case 'EMAIL_TAKEN':
            return 'Этот e-mail уже зарегистрирован';

          case 'VALIDATION_ERROR':
            return 'Проверьте правильность введённых данных';

          case 'NOT_FOUND':
            return 'Запрашиваемые данные не найдены';

          case 'INTERNAL':
            return 'Что-то пошло не так. Попробуйте позже';
        }
      }
    } catch (_) {
      // Используем стандартное сообщение.
    }

    if (response.statusCode >= 500) {
      return 'Ошибка сервера. Попробуйте позже';
    }

    return isLogin
        ? 'Не удалось войти. Проверьте e-mail и пароль'
        : 'Не удалось выполнить запрос. Проверьте введённые данные';
  }

  // Сохраняем JWT после успешной авторизации.
  Future<void> _saveToken(
    http.Response response, {
    bool isLogin = false,
  }) async {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_friendlyError(response, isLogin: isLogin));
    }

    final data = jsonDecode(response.body);
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('Не удалось выполнить вход. Попробуйте позже');
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
  }

  // Получаем сохранённый JWT.
  Future<String?> getToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  // Получаем данные текущего пользователя.
  Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Необходимо войти в аккаунт');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить профиль');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Обновляем данные текущего пользователя.
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String specialty,
    required int studyYear,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Необходимо войти в аккаунт');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'specialty': specialty,
        'studyYear': studyYear,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось обновить профиль');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Выход из аккаунта.
  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  // Удаляем аккаунт текущего пользователя.
  Future<void> deleteAccount() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Необходимо войти в аккаунт');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Не удалось удалить аккаунт');
    }

    await logout();
  }
}

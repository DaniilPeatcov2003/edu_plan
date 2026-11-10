import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'auth_service.dart';

class FileService {
  static const String _baseUrl = 'http://10.0.2.2:8080';

  final AuthService _authService = AuthService();

  Future<String> _getToken() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Необходимо войти в аккаунт');
    }

    return token;
  }

  String _getErrorMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map && data['error'] is Map) {
        return data['error']['message']?.toString() ?? fallback;
      }
    } catch (_) {
      // Ответ сервера не содержит JSON.
    }

    return fallback;
  }

  // Загрузка файла на сервер.
  Future<Map<String, dynamic>> upload(PlatformFile file) async {
    final token = await _getToken();

    final fileSize = await file.length();

    if (fileSize == null) {
      throw Exception('Не удалось определить размер файла');
    }

    if (fileSize > 5 * 1024 * 1024) {
      throw Exception('Размер файла не должен превышать 5 МБ');
    }

    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/files'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception(
        _getErrorMessage(response, 'Не удалось загрузить файл'),
      );
    }

    final data = jsonDecode(response.body);
    return Map<String, dynamic>.from(data as Map);
  }

  // Прикрепление загруженного файла к заданию.
  Future<void> attachToTask(String taskId, int fileId) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/tasks/$taskId/files/$fileId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception(
        _getErrorMessage(response, 'Не удалось прикрепить файл к заданию'),
      );
    }
  }

  // Получение файлов, прикреплённых к заданию.
  Future<List<Map<String, dynamic>>> getTaskFiles(String taskId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/tasks/$taskId/files'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response, 'Не удалось получить список файлов'),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('Некорректный ответ сервера');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // Скачивание файла и открытие на устройстве.
  Future<void> downloadAndOpen(String fileId, String fileName) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/files/$fileId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response, 'Не удалось скачать файл'),
      );
    }

    final directory = await getTemporaryDirectory();

    final safeName = fileName.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    final file = File('${directory.path}/${fileId}_$safeName');

    await file.writeAsBytes(response.bodyBytes, flush: true);

    final result = await OpenFilex.open(file.path);

    if (result.type != ResultType.done) {
      throw Exception(
        result.message.isNotEmpty
            ? result.message
            : 'Не удалось открыть файл',
      );
    }
  }

  // Удаление связи файла с заданием.
  Future<void> detachFromTask(String taskId, int fileId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$_baseUrl/tasks/$taskId/files/$fileId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception(
        _getErrorMessage(
          response,
          'Не удалось удалить файл из задания',
        ),
      );
    }
  }
}
import 'package:flutter/foundation.dart';

import '../data/course_repository.dart';
import '../data/result.dart';
import 'course.dart';
import 'course_page.dart';

class CourseModel extends ChangeNotifier {
  CourseModel({required this.repository});

  final CourseRepository repository;
  final List<Course> _courses = [];

  static const int pageSize = 20;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 0;
  int _total = 0;
  String _search = '';

  Course? byId(String id) {
    for (final course in _courses) {
      if (course.id == id) {
        return course;
      }
    }

    return null;
  }

  List<Course> get courses => List.unmodifiable(_courses);

  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  String? get errorMessage => _errorMessage;

  int get total => _total;

  bool get hasMore => _courses.length < _total;

  // Загрузка первой страницы.
  Future<void> load({String? search}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _search = search ?? _search;
    _currentPage = 0;
    _courses.clear();
    notifyListeners();

    final result = await repository.fetchAll(
      page: 1,
      limit: pageSize,
      search: _search,
    );

    if (result is Ok<CoursePage>) {
      _courses.addAll(result.value.items);
      _currentPage = result.value.page;
      _total = result.value.total;
    } else if (result is Err<CoursePage>) {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Загрузка следующей страницы.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;

    final result = await repository.fetchAll(
      page: nextPage,
      limit: pageSize,
      search: _search,
    );

    if (result is Ok<CoursePage>) {
      _courses.addAll(result.value.items);
      _currentPage = result.value.page;
      _total = result.value.total;
    } else if (result is Err<CoursePage>) {
      _errorMessage = result.message;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // Добавление курса.
  Future<String?> addCourse(Course course) async {
    final result = await repository.create(course);

    if (result is Ok<Course>) {
      await load(search: _search);
      return null;
    }

    return (result as Err<Course>).message;
  }

  // Изменение курса.
  Future<String?> updateCourse(
    Course oldCourse,
    Course updatedCourse,
  ) async {
    final result = await repository.update(oldCourse, updatedCourse);

    if (result is Ok<Course>) {
      final index = _courses.indexWhere(
        (item) => item.id == oldCourse.id,
      );

      if (index != -1) {
        _courses[index] = result.value;
        notifyListeners();
      }

      return null;
    }

    return (result as Err<Course>).message;
  }

  // Удаление курса.
  Future<String?> deleteCourse(Course course) async {
    final result = await repository.delete(course);

    if (result is Ok<void>) {
      _courses.removeWhere((item) => item.id == course.id);
      _total = (_total - 1).clamp(0, _total);
      notifyListeners();
      return null;
    }

    return (result as Err<void>).message;
  }
}
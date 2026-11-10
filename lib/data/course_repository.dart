import '../models/course.dart';
import '../models/course_page.dart';
import 'result.dart';

abstract interface class CourseRepository {
  // Получить список курсов.
  Future<Result<CoursePage>> fetchAll({
    int page = 1,
    int limit = 20,
    String search = '',
  });

  // Получить курс по ID.
  Future<Result<Course>> fetchById(String id);

  // Создать курс.
  Future<Result<Course>> create(Course course);

  // Изменить курс.
  Future<Result<Course>> update(
    Course oldCourse,
    Course updatedCourse,
  );

  // Удалить курс.
  Future<Result<void>> delete(Course course);
}

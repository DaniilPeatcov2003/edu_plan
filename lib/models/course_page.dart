import 'course.dart';

class CoursePage {
  const CoursePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Course> items;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;
}
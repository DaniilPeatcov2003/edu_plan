class CourseSession {
  final String id;
  final String day;
  final String time;
  final String room;
  final String format;

  const CourseSession({
    required this.id,
    required this.day,
    required this.time,
    required this.room,
    this.format = 'Очное',
  });
}

class Course {
  final String id;
  final String name;
  final String teacher;
  final List<CourseSession> sessions;

  const Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.sessions,
  });

  // Временная совместимость со старым кодом.
  String get day => sessions.first.day;
  String get time => sessions.first.time;
  String get room => sessions.first.room;
}

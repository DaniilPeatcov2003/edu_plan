class Task {
  final String id;
  final String title;
  final String course;
  final String? courseId;
  final String deadline;
  final String status;
  final String priority;

  const Task({
    required this.id,
    required this.title,
    required this.course,
    this.courseId,
    required this.deadline,
    required this.status,
    required this.priority,
  });

  Task copyWith({
    String? status,
  }) {
    return Task(
      id: id,
      title: title,
      course: course,
      courseId: courseId,
      deadline: deadline,
      status: status ?? this.status,
      priority: priority,
    );
  }
}

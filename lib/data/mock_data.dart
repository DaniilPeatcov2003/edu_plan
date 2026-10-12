class Course {
  final String id;
  final String name;
  final String teacher;
  final String day;
  final String time;
  final String room;

  const Course({
    required this.id,
    required this.name,
    required this.teacher,
    required this.day,
    required this.time,
    required this.room,
  });
}

class Task {
  final String title;
  final String course;
  final String deadline;
  final String status;
  final String priority;

  const Task({
    required this.title,
    required this.course,
    required this.deadline,
    required this.status,
    required this.priority,
  });
}

const List<Course> mockCourses = [
  Course(
    id: '1',
    name: 'Программирование мобильных приложений',
    teacher: 'Ionel Antohi',
    day: 'Понедельник',
    time: '10:00',
    room: '204',
  ),
  Course(
    id: '2',
    name: 'Компьютерные сети',
    teacher: 'Andrei Popescu',
    day: 'Вторник',
    time: '12:00',
    room: '305',
  ),
  Course(
    id: '3',
    name: 'Базы данных',
    teacher: 'Maria Rusu',
    day: 'Среда',
    time: '09:00',
    room: '201',
  ),
  Course(
    id: '4',
    name: 'Веб-программирование',
    teacher: 'Victor Munteanu',
    day: 'Среда',
    time: '14:00',
    room: '307',
  ),
  Course(
    id: '5',
    name: 'Информационные системы',
    teacher: 'Elena Ceban',
    day: 'Четверг',
    time: '10:00',
    room: '210',
  ),
  Course(
    id: '6',
    name: 'Разработка программного обеспечения',
    teacher: 'Ion Popa',
    day: 'Четверг',
    time: '13:00',
    room: '204',
  ),
  Course(
    id: '7',
    name: 'Анализ и проектирование систем',
    teacher: 'Ana Ciobanu',
    day: 'Пятница',
    time: '09:00',
    room: '302',
  ),
  Course(
    id: '8',
    name: 'Управление IT-проектами',
    teacher: 'Daniel Cojocaru',
    day: 'Пятница',
    time: '12:00',
    room: '105',
  ),
];

const List<Task> mockTasks = [
  Task(
    title: 'Разработать статический UI',
    course: 'Программирование мобильных приложений',
    deadline: '03.10.2026',
    status: 'В процессе',
    priority: 'Высокий',
  ),
  Task(
    title: 'Настроить VLAN в Packet Tracer',
    course: 'Компьютерные сети',
    deadline: '05.10.2026',
    status: 'Не начато',
    priority: 'Высокий',
  ),
  Task(
    title: 'Создать таблицы базы данных',
    course: 'Базы данных',
    deadline: '07.10.2026',
    status: 'В процессе',
    priority: 'Средний',
  ),
  Task(
    title: 'Создать страницу авторизации',
    course: 'Веб-программирование',
    deadline: '09.10.2026',
    status: 'Не начато',
    priority: 'Средний',
  ),
  Task(
    title: 'Описать архитектуру системы',
    course: 'Информационные системы',
    deadline: '11.10.2026',
    status: 'Завершено',
    priority: 'Низкий',
  ),
  Task(
    title: 'Подготовить UML-диаграмму',
    course: 'Анализ и проектирование систем',
    deadline: '13.10.2026',
    status: 'Не начато',
    priority: 'Средний',
  ),
  Task(
    title: 'Создать Git-репозиторий проекта',
    course: 'Разработка программного обеспечения',
    deadline: '15.10.2026',
    status: 'Завершено',
    priority: 'Низкий',
  ),
  Task(
    title: 'Подготовить план IT-проекта',
    course: 'Управление IT-проектами',
    deadline: '17.10.2026',
    status: 'В процессе',
    priority: 'Высокий',
  ),
];
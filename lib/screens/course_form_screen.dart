import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/course_model.dart';

class CourseFormScreen extends StatefulWidget {
  const CourseFormScreen({
    super.key,
    this.courseId,
  });

  final String? courseId;

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();

  final List<String> _days = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
  ];

  final List<_SessionDraft> _sessions = [];

  bool _isSaving = false;
  bool get _isEditing => widget.courseId != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final course = context.read<CourseModel>().byId(widget.courseId!);

        if (course != null) {
          _nameController.text = course.name;
          _teacherController.text = course.teacher;

          for (final session in course.sessions) {
            _sessions.add(
              _SessionDraft(
                day: session.day,
                time: session.time,
                room: session.room,
                format: session.format,
              ),
            );
          }

          setState(() {});
        }
      });
    } else {
      _sessions.add(_SessionDraft());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();

    for (final session in _sessions) {
      session.dispose();
    }

    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните это поле';
    }
    return null;
  }

  void _addSession() {
    setState(() {
      _sessions.add(_SessionDraft());
    });
  }

  void _removeSession(int index) {
    if (_sessions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('У курса должно быть хотя бы одно занятие'),
        ),
      );
      return;
    }

    setState(() {
      _sessions.removeAt(index).dispose();
    });
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sessions.any((session) => session.day == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите день для каждого занятия')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final courseModel = context.read<CourseModel>();

    final course = Course(
      id: widget.courseId ?? '',
      name: _nameController.text.trim(),
      teacher: _teacherController.text.trim(),
      sessions: _sessions.map((session) {
        return CourseSession(
          id: '',
          day: session.day!,
          time: session.timeController.text.trim(),
          room: session.roomController.text.trim(),
          format: session.format,
        );
      }).toList(),
    );

    String? error;

    if (_isEditing) {
      final oldCourse = courseModel.byId(widget.courseId!);

      if (oldCourse == null) {
        error = 'Курс не найден';
      } else {
        error = await courseModel.updateCourse(oldCourse, course);
      }
    } else {
      error = await courseModel.addCourse(course);
    }

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Курс обновлён' : 'Курс добавлен',
        ),
      ),
    );

    context.pop();
  }

  Widget _buildSessionCard(int index) {
    final session = _sessions[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Занятие ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Удалить занятие',
                  onPressed: () => _removeSession(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: session.day,
              decoration: const InputDecoration(
                labelText: 'День недели',
                border: OutlineInputBorder(),
              ),
              items: _days.map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => session.day = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Выберите день недели';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: session.format,
              decoration: const InputDecoration(
                labelText: 'Формат занятия',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Очное',
                  child: Text('Очное'),
                ),
                DropdownMenuItem(
                  value: 'Заочное',
                  child: Text('Заочное'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => session.format = value);
                }
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: session.timeController,
              decoration: const InputDecoration(
                labelText: 'Время (например, 10:00)',
                border: OutlineInputBorder(),
              ),
              validator: _validateRequired,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: session.roomController,
              decoration: const InputDecoration(
                labelText: 'Аудитория',
                border: OutlineInputBorder(),
              ),
              validator: _validateRequired,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование курса' : 'Новый курс'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название курса',
                border: OutlineInputBorder(),
              ),
              validator: _validateRequired,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: 'Преподаватель',
                border: OutlineInputBorder(),
              ),
              validator: _validateRequired,
            ),
            const SizedBox(height: 24),

            Text(
              'Расписание занятий',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            ...List.generate(
              _sessions.length,
              (index) => _buildSessionCard(index),
            ),

            OutlinedButton.icon(
              onPressed: _addSession,
              icon: const Icon(Icons.add),
              label: const Text('Добавить занятие'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveCourse,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : Text(
                      _isEditing
                          ? 'Сохранить изменения'
                          : 'Добавить курс',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionDraft {
  _SessionDraft({
    this.day,
    String time = '',
    String room = '',
    this.format = 'Очное',
  })  : timeController = TextEditingController(text: time),
        roomController = TextEditingController(text: room);

  String? day;
  String format;

  final TextEditingController timeController;
  final TextEditingController roomController;

  void dispose() {
    timeController.dispose();
    roomController.dispose();
  }
}
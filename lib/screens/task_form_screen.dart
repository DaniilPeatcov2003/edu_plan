import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _deadlineController = TextEditingController();

  String? _selectedCourse;
  String? _selectedPriority;

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String value) {
    final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$')
        .firstMatch(value.trim());

    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);

    final date = DateTime(year, month, day);

    if (date.day != day ||
        date.month != month ||
        date.year != year) {
      return null;
    }

    return date;
  }

  String? _validateDeadline(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Укажите дедлайн';
    }

    final date = _parseDate(value);

    if (date == null) {
      return 'Введите дату в формате ДД.ММ.ГГГГ';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!date.isAfter(today)) {
      return 'Дедлайн должен быть в будущем';
    }

    return null;
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Задание "${_titleController.text.trim()}" проверено',
        ),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое задание'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название задания
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Название задания',
                  hintText: 'Например, разработать UI',
                  prefixIcon: Icon(Icons.assignment_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название задания';
                  }

                  if (value.trim().length < 3) {
                    return 'Минимум 3 символа';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Выбор курса с валидацией
              FormField<String>(
                initialValue: _selectedCourse,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите курс';
                  }
                  return null;
                },
                builder: (field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Курс',
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: const OutlineInputBorder(),
                      errorText: field.errorText,
                    ),
                    child: DropdownMenu<String>(
                      key: ValueKey(_selectedCourse),
                      initialSelection: _selectedCourse,
                      expandedInsets: EdgeInsets.zero,
                      onSelected: (value) {
                        setState(() {
                          _selectedCourse = value;
                          field.didChange(value);
                        });
                      },
                      dropdownMenuEntries: mockCourses
                          .map(
                            (course) => DropdownMenuEntry<String>(
                              value: course.name,
                              label: course.name,
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Дедлайн
              TextFormField(
                controller: _deadlineController,
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9.]'),
                  ),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Дедлайн',
                  hintText: 'ДД.ММ.ГГГГ',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateDeadline,
              ),

              const SizedBox(height: 16),

              // Выбор приоритета с валидацией
              FormField<String>(
                initialValue: _selectedPriority,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите приоритет';
                  }
                  return null;
                },
                builder: (field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Приоритет',
                      prefixIcon: const Icon(Icons.flag_outlined),
                      border: const OutlineInputBorder(),
                      errorText: field.errorText,
                    ),
                    child: DropdownMenu<String>(
                      key: ValueKey(_selectedPriority),
                      initialSelection: _selectedPriority,
                      expandedInsets: EdgeInsets.zero,
                      onSelected: (value) {
                        setState(() {
                          _selectedPriority = value;
                          field.didChange(value);
                        });
                      },
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(
                          value: 'Низкий',
                          label: 'Низкий',
                        ),
                        DropdownMenuEntry(
                          value: 'Средний',
                          label: 'Средний',
                        ),
                        DropdownMenuEntry(
                          value: 'Высокий',
                          label: 'Высокий',
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Сохранение
              FilledButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Сохранить задание'),
              ),

              const SizedBox(height: 8),

              // Отмена
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

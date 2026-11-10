
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../services/file_service.dart';
import '../models/task_model.dart';
import '../models/task.dart';
import '../models/course_model.dart';
import '../data/result.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _deadlineController = TextEditingController();

  final FileService _fileService = FileService();

  String? _selectedCourseId;
  String? _selectedPriority;

  Task? _originalTask;

  PlatformFile? _selectedFile;
  int? _selectedFileSize;
  int? _uploadedFileId;

  List<Map<String, dynamic>> _existingFiles = [];

  bool _isLoadingFiles = false;
  bool _filesLoadStarted = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    context.read<CourseModel>().load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  // Выбор нового файла.
  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles();

      if (files.isEmpty) return;

      final file = files.first;
      final fileSize = await file.length();

      if (fileSize == null) {
        throw Exception('Не удалось определить размер файла');
      }

      if (fileSize > 5 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Размер файла не должен превышать 5 МБ'),
          ),
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedFile = file;
        _selectedFileSize = fileSize;
        _uploadedFileId = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка выбора файла: $e'),
        ),
      );
    }
  }

  // Удаление нового, ещё не загруженного файла.
  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileSize = null;
      _uploadedFileId = null;
    });
  }

  // Получение существующих вложений задания.
  Future<void> _loadExistingFiles(String taskId) async {
    if (!mounted) return;

    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final files = await _fileService.getTaskFiles(taskId);

      if (!mounted) return;

      setState(() {
        _existingFiles = files;
        _isLoadingFiles = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingFiles = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось загрузить вложения: $e'),
        ),
      );
    }
  }

  // Подтверждение и удаление существующего вложения.
  Future<void> _removeExistingFile(
    Map<String, dynamic> file,
  ) async {
    if (_isUploading) return;

    final fileId = int.tryParse(file['id'].toString());

    if (fileId == null || widget.taskId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удалить вложение?'),
          content: Text(
            'Файл "${file['name']}" будет откреплён от задания.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      setState(() {
        _isUploading = true;
      });

      await _fileService.detachFromTask(
        widget.taskId!,
        fileId,
      );

      if (!mounted) return;

      setState(() {
        _existingFiles.removeWhere(
          (item) => item['id'].toString() == fileId.toString(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вложение успешно удалено'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления файла: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Открытие существующего файла.
  Future<void> _openExistingFile(
    Map<String, dynamic> file,
  ) async {
    try {
      await _fileService.downloadAndOpen(
        file['id'].toString(),
        file['name'].toString(),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось открыть файл: $e'),
        ),
      );
    }
  }

  // Форматирование размера файла.
  String _formatFileSize(dynamic value) {
    final size = (value as num?)?.toInt() ?? 0;

    if (size < 1024) {
      return '$size Б';
    }

    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} КБ';
    }

    return '${(size / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  // Определение иконки по типу файла.
  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Icons.image_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
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

  // Сохранение задания и прикрепление нового файла.
  Future<void> _saveTask() async {
    if (_isUploading) return;

    if (!_formKey.currentState!.validate()) return;

    final original = _originalTask;
    final isNewTask = widget.taskId == null;

    final selectedCourse = context
        .read<CourseModel>()
        .courses
        .where((course) => course.id == _selectedCourseId)
        .firstOrNull;

    if (selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите доступный курс'),
        ),
      );
      return;
    }

    final task = Task(
      id: original?.id ?? '',
      title: _titleController.text.trim(),
      course: selectedCourse.name,
      courseId: selectedCourse.id,
      deadline: _deadlineController.text.trim(),
      status: original?.status ?? 'Не начато',
      priority: _selectedPriority!,
    );

    final model = context.read<TaskModel>();

    setState(() {
      _isUploading = true;
    });

    bool taskSaved = false;

    try {
      late Task savedTask;

      // Создание или обновление задания.
      if (original == null) {
        final result = await model.addTask(task);

        if (result is Err<Task>) {
          throw Exception(result.message);
        }

        savedTask = (result as Ok<Task>).value;
      } else {
        final error = await model.updateTask(original, task);

        if (error != null) {
          throw Exception(error);
        }

        savedTask = task;
      }

      taskSaved = true;
      _originalTask = savedTask;

      // Загрузка и прикрепление нового файла.
      if (_selectedFile != null) {
        if (_uploadedFileId == null) {
          final uploadedFile = await _fileService.upload(
            _selectedFile!,
          );

          final fileId = int.tryParse(
            uploadedFile['id'].toString(),
          );

          if (fileId == null) {
            throw Exception(
              'Сервер не вернул ID загруженного файла',
            );
          }

          _uploadedFileId = fileId;
        }

        await _fileService.attachToTask(
          savedTask.id,
          _uploadedFileId!,
        );

        // Обновляем задания после прикрепления файла.
        await model.load();

        if (!mounted) return;

        setState(() {
          _selectedFile = null;
          _selectedFileSize = null;
          _uploadedFileId = null;
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNewTask
                ? 'Задание "${savedTask.title}" добавлено'
                : 'Задание "${savedTask.title}" обновлено',
          ),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            taskSaved
                ? 'Задание сохранено, но файл не удалось прикрепить: $errorMessage'
                : 'Ошибка сохранения задания: $errorMessage',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final courseModel = context.read<CourseModel>();

    if (!courseModel.isLoading &&
        _selectedCourseId != null &&
        !courseModel.courses.any(
          (course) => course.id == _selectedCourseId,
        )) {
      _selectedCourseId = null;
    }

    if (widget.taskId == null || _originalTask != null) {
      return;
    }

    final model = context.read<TaskModel>();

    if (model.isLoading || model.errorMessage != null) {
      return;
    }

    final task = model.byId(widget.taskId!);

    if (task != null) {
      _originalTask = task;

      _titleController.text = task.title;
      _deadlineController.text = task.deadline;
      _selectedCourseId = task.courseId;
      _selectedPriority = task.priority;

      if (!courseModel.courses.any(
        (course) => course.id == task.courseId,
      )) {
        _selectedCourseId = null;
      }

      // Загружаем вложения только один раз.
      if (!_filesLoadStarted) {
        _filesLoadStarted = true;
        _loadExistingFiles(task.id);
      }
    }
  }

  // Отображение блока вложений.
  Widget _buildAttachments(bool isEditing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Вложения',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Существующие файлы.
            if (isEditing) ...[
              const SizedBox(height: 12),

              if (_isLoadingFiles)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_existingFiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'К заданию пока не прикреплены файлы.',
                    style: TextStyle(fontSize: 13),
                  ),
                )
              else
                ..._existingFiles.map((file) {
                  final fileName = file['name'].toString();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _getFileIcon(fileName),
                      size: 28,
                    ),
                    title: Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatFileSize(file['size']),
                    ),
                    onTap: () => _openExistingFile(file),
                    trailing: IconButton(
                      tooltip: 'Удалить вложение',
                      onPressed: _isUploading
                          ? null
                          : () => _removeExistingFile(file),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  );
                }),
            ],

            const SizedBox(height: 8),

            // Выбор нового файла.
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Выбрать файл'),
            ),

            // Отображение нового выбранного файла.
            if (_selectedFile != null) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.upload_file_outlined,
                ),
                title: Text(
                  _selectedFile!.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${(_selectedFileSize! / 1024).toStringAsFixed(1)} КБ',
                ),
                trailing: IconButton(
                  onPressed: _isUploading ? null : _removeFile,
                  icon: const Icon(Icons.close),
                ),
              ),
            ],

            const SizedBox(height: 8),

            const Text(
              'Нажмите на существующий файл, чтобы открыть его. '
              'Кнопка корзины открепляет файл от задания. '
              'Новый файл будет загружен после сохранения. '
              'Максимальный размер — 5 МБ.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseModel = context.watch<CourseModel>();
    final taskModel = context.watch<TaskModel>();

    final isEditing = widget.taskId != null;

    if (courseModel.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? 'Редактирование задания' : 'Новое задание',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (courseModel.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? 'Редактирование задания' : 'Новое задание',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Не удалось загрузить курсы:\n${courseModel.errorMessage}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    context.read<CourseModel>().load();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (courseModel.courses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? 'Редактирование задания' : 'Новое задание',
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 48),
                SizedBox(height: 12),
                Text(
                  'Нет доступных курсов',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Сначала добавьте курс, чтобы создавать задания.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isEditing && taskModel.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование задания'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (isEditing && taskModel.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование задания'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(taskModel.errorMessage!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  context.read<TaskModel>().load();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (isEditing && _originalTask == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование задания'),
        ),
        body: const Center(
          child: Text('Задание не найдено'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Редактирование задания' : 'Новое задание',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название задания.
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

              // Выбор курса.
              FormField<String>(
                initialValue: _selectedCourseId,
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
                      key: ValueKey(_selectedCourseId),
                      initialSelection: _selectedCourseId,
                      expandedInsets: EdgeInsets.zero,
                      onSelected: (value) {
                        setState(() {
                          _selectedCourseId = value;
                          field.didChange(value);
                        });
                      },
                      dropdownMenuEntries: courseModel.courses
                          .map(
                            (course) => DropdownMenuEntry<String>(
                              value: course.id,
                              label: course.name,
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Дедлайн.
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

              // Приоритет.
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

              // Вложения.
              _buildAttachments(isEditing),

              const SizedBox(height: 24),

              // Сохранение.
              FilledButton.icon(
                onPressed: _isUploading ? null : _saveTask,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isUploading
                      ? 'Сохранение...'
                      : isEditing
                          ? 'Сохранить изменения'
                          : 'Создать задание',
                ),
              ),
              const SizedBox(height: 8),

              // Отмена.
              OutlinedButton(
                onPressed: _isUploading ? null : () => context.pop(),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

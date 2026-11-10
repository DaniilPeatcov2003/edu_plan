import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/file_service.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStatusChanged,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onStatusChanged;

  static const List<String> statuses = [
    'Не начато',
    'В процессе',
    'Завершено',
  ];

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final FileService _fileService = FileService();

  late Future<List<Map<String, dynamic>>> _filesFuture;

  final Set<String> _downloadingFiles = {};

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.task.id != widget.task.id ||
        oldWidget.task != widget.task) {
      _loadFiles();
    }
  }

  void _loadFiles() {
    _filesFuture = _fileService.getTaskFiles(widget.task.id);
  }

  String _formatFileSize(dynamic size) {
    final bytes = int.tryParse(size.toString()) ?? 0;

    if (bytes < 1024) {
      return '$bytes Б';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  IconData _getFileIcon(String name) {
    final extension = name.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _downloadFile(
    String fileId,
    String fileName,
  ) async {
    if (_downloadingFiles.contains(fileId)) return;

    setState(() {
      _downloadingFiles.add(fileId);
    });

    try {
      await _fileService.downloadAndOpen(fileId, fileName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл "$fileName" открыт'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingFiles.remove(fileId);
        });
      }
    }
  }

  Widget _buildAttachments() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _filesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Не удалось загрузить вложения',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          );
        }

        final files = snapshot.data ?? [];

        if (files.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Прикреплённые файлы',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              ...files.map((file) {
                final name = file['name']?.toString() ?? 'Файл';
                final size = file['size'];
                final fileId = file['id']?.toString() ?? '';
                final isDownloading =
                    _downloadingFiles.contains(fileId);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(_getFileIcon(name)),
                  title: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatFileSize(size)),
                  trailing: isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.download_outlined),
                  onTap: fileId.isEmpty || isDownloading
                      ? null
                      : () => _downloadFile(fileId, name),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    final currentStatus = TaskCard.statuses.contains(task.status)
        ? task.status
        : TaskCard.statuses.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: widget.onTap,
              leading: CircleAvatar(
                child: Icon(
                  task.status == 'Завершено'
                      ? Icons.check
                      : Icons.assignment_outlined,
                ),
              ),
              title: Text(task.title),
              subtitle: Text(
                '${task.course}\n'
                'Срок: ${task.deadline} • '
                'Приоритет: ${task.priority}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: currentStatus,
                    isDense: true,
                    underline: const SizedBox(),
                    items: TaskCard.statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: widget.onStatusChanged == null
                        ? null
                        : (value) {
                            if (value != null) {
                              widget.onStatusChanged!(value);
                            }
                          },
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Действия с заданием',
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit?.call();
                      } else if (value == 'delete') {
                        widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Редактировать'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Удалить'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildAttachments(),
          ],
        ),
      ),
    );
  }
}
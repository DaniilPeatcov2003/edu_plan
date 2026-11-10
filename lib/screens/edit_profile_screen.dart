
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _specialtyController;

  late int _studyYear;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.profile['name']?.toString() ?? '',
    );

    _specialtyController = TextEditingController(
      text: widget.profile['specialty']?.toString() ?? '',
    );

    _studyYear = int.tryParse(
          widget.profile['studyYear']?.toString() ?? '',
        ) ??
        1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedProfile =
          await context.read<AuthService>().updateProfile(
                name: _nameController.text.trim(),
                specialty: _specialtyController.text.trim(),
                studyYear: _studyYear,
              );

      if (!mounted) return;

      Navigator.of(context).pop(updatedProfile);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите имя';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                labelText: 'Специальность',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите специальность';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _studyYear,
              decoration: const InputDecoration(
                labelText: 'Курс обучения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: List.generate(
                6,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1} курс'),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _studyYear = value);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving ? 'Сохранение...' : 'Сохранить изменения',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

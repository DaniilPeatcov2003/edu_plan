
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../widgets/course_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _searchDebounce;

  String _selectedDay = 'Все';

  final List<String> _days = [
    'Все',
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
  ];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CourseModel>().load();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CourseModel>().loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () {
        if (!mounted) return;

        context.read<CourseModel>().load(search: value);
      },
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    context.read<CourseModel>().load(search: '');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/courses/new');
            },
            icon: const Icon(Icons.add),
            tooltip: 'Добавить курс',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск курса',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.tune),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _days.map((day) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(day),
                    selected: _selectedDay == day,
                    onSelected: (_) {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Consumer<CourseModel>(
              builder: (context, courseModel, child) {
                if (courseModel.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (courseModel.errorMessage != null &&
                    courseModel.courses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(courseModel.errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => courseModel.load(
                            search: _searchController.text,
                          ),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                final courses = courseModel.courses.where((course) {
                  return _selectedDay == 'Все' ||
                      course.sessions.any(
                        (session) => session.day == _selectedDay,
                      );
                }).toList();

                if (courses.isEmpty) {
                  return const Center(
                    child: Text('Курсы не найдены'),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length +
                      (courseModel.isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index >= courses.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final course = courses[index];

                    return CourseCard(
                      course: course,
                      onTap: () {
                        context.push('/courses/${course.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

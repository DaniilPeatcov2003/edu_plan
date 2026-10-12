import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/mock_data.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/course_details_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationScreen(
          navigationShell: navigationShell,
        );
      },
      branches: [
        // Главная
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Расписание
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/schedule',
              builder: (context, state) => const ScheduleScreen(),
            ),
          ],
        ),

        // Курсы
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/courses',
              builder: (context, state) => const CoursesScreen(),
            ),

            // Детали курса открываются по его ID.
            GoRoute(
              path: '/courses/:id',
              builder: (context, state) {
                final id = state.pathParameters['id'];

                final course = mockCourses.where(
                  (course) => course.id == id,
                );

                if (course.isEmpty) {
                  return const Scaffold(
                    body: Center(
                      child: Text('Курс не найден'),
                    ),
                  );
                }

                return CourseDetailsScreen(
                  course: course.first,
                );
              },
            ),
          ],
        ),

        // Задания
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksScreen(),
            ),
            GoRoute(
              path: '/tasks/new',
              builder: (context, state) => const TaskFormScreen(),
            ),
          ],
        ),

        // Профиль
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

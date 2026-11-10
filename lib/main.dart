import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/http_task_repository.dart';
import 'data/http_course_repository.dart';
import 'models/task_model.dart';
import 'models/course_model.dart';
import 'models/theme_model.dart';
import 'router.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();

  // Проверяем, сохранён ли JWT.
  final token = await authService.getToken();
  final isAuthenticated = token != null && token.isNotEmpty;

  // Загружаем сохранённую тему.
  final themeModel = ThemeModel();
  await themeModel.loadTheme();

  // Создаём маршрутизатор.
  final router = createAppRouter(
    isAuthenticated: isAuthenticated,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => authService,
        ),

        ChangeNotifierProvider<ThemeModel>.value(
          value: themeModel,
        ),

        Provider<HttpTaskRepository>(
          create: (context) => HttpTaskRepository(
            authService: context.read<AuthService>(),
          ),
        ),

        ChangeNotifierProvider<TaskModel>(
          create: (context) => TaskModel(
            repository: context.read<HttpTaskRepository>(),
          ),
        ),

        Provider<HttpCourseRepository>(
          create: (context) => HttpCourseRepository(
            authService: context.read<AuthService>(),
          ),
        ),

        ChangeNotifierProvider<CourseModel>(
          create: (context) => CourseModel(
            repository: context.read<HttpCourseRepository>(),
          ),
        ),
      ],
      child: EduPlanApp(router: router),
    ),
  );
}

class EduPlanApp extends StatelessWidget {
  final GoRouter router;

  const EduPlanApp({
    super.key,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeModel>();

    return MaterialApp.router(
      title: 'EduPlan',
      debugShowCheckedModeBanner: false,

      // Светлая тема.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Тёмная тема.
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Выбираем тему из ThemeModel.
      themeMode: themeModel.themeMode,

      routerConfig: router,
    );
  }
}

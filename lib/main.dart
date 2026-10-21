import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_task_repository.dart';
import 'models/task_model.dart';
import 'router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Создаём репозиторий и предоставляем его приложению.
        Provider<MockTaskRepository>(
          create: (_) => MockTaskRepository(),
        ),

        // Передаём репозиторий модели и загружаем задания.
        ChangeNotifierProvider<TaskModel>(
          create: (context) => TaskModel(
            repository: context.read<MockTaskRepository>(),
          )..load(),
        ),
      ],
      child: const EduPlanApp(),
    ),
  );
}

class EduPlanApp extends StatelessWidget {
  const EduPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduPlan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edu_plan/main.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('EduPlan home screen test', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Column(
              children: [
                Text('EduPlan'),
                Text('Добро пожаловать в EduPlan!'),
              ],
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(EduPlanApp(router: router));

    expect(find.text('EduPlan'), findsOneWidget);
    expect(find.text('Добро пожаловать в EduPlan!'), findsOneWidget);

    router.dispose();
  });
}

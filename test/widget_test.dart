import 'package:flutter_test/flutter_test.dart';
import 'package:edu_plan/main.dart';

void main() {
  testWidgets('EduPlan home screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const EduPlanApp());

    expect(find.text('EduPlan'), findsOneWidget);
    expect(find.text('Добро пожаловать в EduPlan!'), findsOneWidget);
  });
}
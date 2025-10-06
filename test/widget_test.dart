import 'package:flutter_test/flutter_test.dart';
import 'package:meal_planner_app_local_version/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const MealPlannerApp());
    expect(find.text('Meal Planner'), findsOneWidget);
  });
}
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MealPlannerApp());
}

class MealPlannerApp extends StatelessWidget {
  const MealPlannerApp({super.key});

  static final _router = AppRouter().router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Keto Meal Planner',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

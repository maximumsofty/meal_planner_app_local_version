import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MealPlannerApp());
}

class MealPlannerApp extends StatelessWidget {
  MealPlannerApp({super.key});

  // Not static - created after Firebase is initialized
  final _router = AppRouter().router;

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

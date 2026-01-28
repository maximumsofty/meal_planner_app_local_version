import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  GoRouter? router;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Create router AFTER Firebase is initialized
    router = AppRouter().router;
  } catch (e, stack) {
    initError = 'Initialization error:\n\n$e\n\n$stack';
  }

  runApp(MealPlannerApp(router: router, initError: initError));
}

class MealPlannerApp extends StatelessWidget {
  final GoRouter? router;
  final String? initError;

  const MealPlannerApp({
    super.key,
    required this.router,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    if (initError != null || router == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                initError ?? 'Unknown error: router is null',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Keto Meal Planner',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

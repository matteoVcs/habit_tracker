import 'package:flutter/material.dart';
import 'package:habit_tracker/db/supabase_helper.dart';
import 'package:habit_tracker/habit_list_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'style/app_theme.dart' show AppTheme;
import 'style/theme_controller.dart';
import 'login_page.dart';

const supabaseUrl = 'https://zepzqfoxtmcpfjbzheoo.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplcHpxZm94dG1jcGZqYnpoZW9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0NjMzMjMsImV4cCI6MjA2NzAzOTMyM30.hNyOy_xgd3f6Nx9tt2nnPWvrtvTpOzFipzaQcBasRCI';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) => HabitTrackerApp(themeMode: mode),
    ),
  );
}

class HabitTrackerApp extends StatelessWidget {
  final ThemeMode themeMode;
  const HabitTrackerApp({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context) {
     final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: session != null ? const HabitListPage() : const LoginPage(),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class SupabaseHelper {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://zepzqfoxtmcpfjbzheoo.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplcHpxZm94dG1jcGZqYnpoZW9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0NjMzMjMsImV4cCI6MjA2NzAzOTMyM30.hNyOy_xgd3f6Nx9tt2nnPWvrtvTpOzFipzaQcBasRCI',
    );
  }

  // Connexion
  static Future<bool> loginUser(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.session != null;
  }

  // Inscription
  static Future<bool> registerUser(String email, String password) async {
    final res = await supabase.auth.signUp(email: email, password: password);
    return res.user != null;
  }

  // Récupération des habitudes
  static Future<List<Map<String, dynamic>>> getHabits() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await supabase.from('habits').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(res);
  }

  // Ajout d'une habitude
  static Future<void> addHabit(String name) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('habits').insert({'name': name, 'user_id': userId});
  }

  // Suppression d'une habitude
  static Future<void> deleteHabit(dynamic id) async {
    await supabase.from('habits').delete().eq('id', id);
    await supabase.from('habit_checks').delete().eq('habit_id', id);
  }

  // Vérifie si une habitude est cochée à une date donnée
  static Future<bool> isHabitChecked(dynamic habitId, String date) async {
    final res = await supabase
        .from('habit_checks')
        .select()
        .eq('habit_id', habitId)
        .eq('date', date);
    return (res as List).isNotEmpty;
  }

  // Coche / décoche une habitude pour une date
  static Future<void> toggleCheck(dynamic habitId, String date) async {
    final checked = await isHabitChecked(habitId, date);
    if (checked) {
      await supabase
          .from('habit_checks')
          .delete()
          .eq('habit_id', habitId)
          .eq('date', date);
    } else {
      await supabase.from('habit_checks').insert({
        'habit_id': habitId,
        'date': date,
      });
    }
  }

  // Récupère le nombre de checks pour les 7 derniers jours
  static Future<int> getWeeklyCheckCount(dynamic habitId, DateTime now) async {
    final start = now
        .subtract(const Duration(days: 6))
        .toIso8601String()
        .split('T')
        .first;
    final end = now.toIso8601String().split('T').first;

    final result = await supabase
        .rpc(
          'count_checks',
          params: {'h_id': habitId, 'start_date': start, 'end_date': end},
        )
        .select();

    return result as int;
  }
}

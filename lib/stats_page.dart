import 'package:flutter/material.dart';
import 'db/supabase_helper.dart';
import 'style/theme_controller.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<Map<String, dynamic>> habits = [];
  Map<int, int> stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final fetchedHabits = await SupabaseHelper.getHabits();
    final statMap = <int, int>{};

    for (var h in fetchedHabits) {
      final count = await SupabaseHelper.getWeeklyCheckCount(
        h['id'],
        DateTime.now(),
      );
      statMap[h['id']] = count;
    }

    setState(() {
      habits = fetchedHabits;
      stats = statMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques hebdomadaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Changer le thème',
            onPressed: () => themeController.toggleTheme(),
          ),
        ],
      ),
      body: habits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: habits.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (ctx, i) {
                final habit = habits[i];
                final count = stats[habit['id']] ?? 0;
                return ListTile(
                  title: Text(
                    habit['name'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Text(
                    '$count / 7',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: count >= 5
                          ? Colors.green
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

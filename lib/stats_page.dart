import 'package:flutter/material.dart';
import 'db/database_helper.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> habits = [];
  Map<int, int> checkCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final allHabits = await dbHelper.getHabits();
    final Map<int, int> counts = {};
    for (var habit in allHabits) {
      final count = await dbHelper.getWeeklyCheckCount(habit['id']);
      counts[habit['id']] = count;
    }

    setState(() {
      habits = allHabits;
      checkCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques hebdomadaires')),
      body: ListView.builder(
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final habit = habits[index];
          final count = checkCounts[habit['id']] ?? 0;
          return ListTile(
            title: Text(habit['name']),
            trailing: Text('$count / 7 jours'),
          );
        },
      ),
    );
  }
}

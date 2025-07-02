import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db/database_helper.dart';
import 'stats_page.dart';
import 'theme_controller.dart';

class HabitListPage extends StatefulWidget {
  const HabitListPage({super.key});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> habits = [];
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final loaded = await dbHelper.getHabits();
    setState(() {
      habits = loaded;
    });
  }

  Future<void> _addHabit() async {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      await dbHelper.addHabit(name);
      _controller.clear();
      await _loadHabits();
    }
  }

  Future<void> _deleteHabit(int id) async {
    await dbHelper.deleteHabit(id);
    await _loadHabits();
  }

  Future<void> _toggleCheck(int habitId) async {
    final isChecked = await dbHelper.isHabitChecked(habitId, today);
    if (isChecked) {
      await dbHelper.uncheckHabit(habitId, today);
    } else {
      await dbHelper.checkHabit(habitId, today);
    }
    setState(() {});
  }

  Widget _buildHabitTile(Map<String, dynamic> habit) {
    return FutureBuilder<bool>(
      future: dbHelper.isHabitChecked(habit['id'], today),
      builder: (context, snapshot) {
        final isChecked = snapshot.data ?? false;
        return ListTile(
          title: Text(habit['name']),
          leading: Checkbox(
            value: isChecked,
            onChanged: (_) => _toggleCheck(habit['id']),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteHabit(habit['id']),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi d’habitudes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Changer thème',
            onPressed: () => themeController.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiques',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatsPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle habitude',
                    ),
                    onSubmitted: (_) => _addHabit(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addHabit),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) => _buildHabitTile(habits[index]),
            ),
          ),
        ],
      ),
    );
  }
}

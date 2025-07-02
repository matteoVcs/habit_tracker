import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db/supabase_helper.dart';
import 'stats_page.dart';
import 'style/theme_controller.dart';

class HabitListPage extends StatefulWidget {
  const HabitListPage({super.key});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage> {
  final TextEditingController _controller = TextEditingController();
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<Map<String, dynamic>> habits = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final loaded = await SupabaseHelper.getHabits();
    setState(() {
      habits = loaded;
    });
  }

  Future<void> _addHabit() async {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      await SupabaseHelper.addHabit(name);
      _controller.clear();
      await _loadHabits();
    }
  }

  Future<void> _deleteHabit(String id) async {
    await SupabaseHelper.deleteHabit(id);
    await _loadHabits();
  }

  Future<void> _toggleHabit(String id) async {
    await SupabaseHelper.toggleCheck(id, today);
    setState(() {});
  }

  Widget _buildHabitTile(Map<String, dynamic> habit) {
    return FutureBuilder<bool>(
      future: SupabaseHelper.isHabitChecked(habit['id'], today),
      builder: (context, snapshot) {
        final isChecked = snapshot.data ?? false;
        return ListTile(
          title: Text(habit['name']),
          leading: Checkbox(
            value: isChecked,
            onChanged: (_) => _toggleHabit(habit['id']),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteHabit(habit['id']),
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHabitsPage() {
    return Column(
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
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addHabit,
                tooltip: 'Ajouter',
              ),
            ],
          ),
        ),
        Expanded(
          child: habits.isEmpty
              ? const Center(child: Text('Aucune habitude ajoutée.'))
              : ListView.builder(
                  itemCount: habits.length,
                  itemBuilder: (context, index) =>
                      _buildHabitTile(habits[index]),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHabitsPage(),
      const StatsPage(),
      const Center(child: Text('Paramètres (à venir)')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi d’habitudes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Changer le thème',
            onPressed: () => themeController.toggleTheme(),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Habitudes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

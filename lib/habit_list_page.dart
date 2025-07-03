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
  if (supabase.auth.currentUser == null) {
    Navigator.of(context).pushReplacementNamed('/');
    return;
  }
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
    final habitToDelete = habits.firstWhere((h) => h['id'] == id);

    // Supprimer immédiatement
    await SupabaseHelper.deleteHabit(id);
    await _loadHabits();

    // Afficher SnackBar avec "Annuler"
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Habitude « ${habitToDelete['name']} » supprimée"),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () async {
            await SupabaseHelper.addHabit(habitToDelete['name']);
            await _loadHabits();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _toggleHabit(String id) async {
    await SupabaseHelper.toggleCheck(id, today);
    setState(() {}); // refresh UI
  }

  Widget _buildHabitCard(Map<String, dynamic> habit) {
    return FutureBuilder<bool>(
      future: SupabaseHelper.isHabitChecked(habit['id'], today),
      builder: (context, snapshot) {
        final isChecked = snapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: Theme.of(context).cardColor,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min, // <- clé pour compacter
                children: [
                  Text(
                    habit['name'],
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  Checkbox(
                    value: isChecked,
                    onChanged: (_) => _toggleHabit(habit['id']),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteHabit(habit['id']),
                  ),
                ],
              ),
            ),
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

  final List<Widget> _pages = [
    const Placeholder(), // remplacé dynamiquement
    const StatsPage(),
  ];

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
          icon: const Icon(Icons.logout),
          tooltip: 'Déconnexion',
          onPressed: () async {
            await supabase.auth.signOut();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
        ),
      ],

      ),
      body: _selectedIndex == 0
          ? Column(
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
                      ),
                    ],
                  ),
                ),
                habits.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text("Aucune habitude ajoutée"),
                      )
                    : SizedBox(
                        height: 80, // 👈 fixe la hauteur des cartes
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: habits.length,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemBuilder: (context, index) =>
                              _buildHabitCard(habits[index]),
                        ),
                      ),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Habitudes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}

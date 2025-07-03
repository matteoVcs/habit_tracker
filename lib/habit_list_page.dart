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
  String? _draggingHabitId;

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
    await SupabaseHelper.deleteHabit(id);
    await _loadHabits();

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
    setState(() {});
  }

  Widget _buildHabitCard(Map<String, dynamic> habit) {
    final String id = habit['id'] ?? '';
    final String name = habit['name'] ?? 'Sans nom';

    if (!_isValidUuid(id))
      return const SizedBox(); // Ne construit rien si id invalide

    return FutureBuilder<bool>(
      future: SupabaseHelper.isHabitChecked(id, today),
      builder: (context, snapshot) {
        final isChecked = snapshot.data ?? false;

        return Draggable<String>(
          data: id,
          onDragStarted: () => setState(() => _draggingHabitId = id),
          onDraggableCanceled: (_, __) =>
              setState(() => _draggingHabitId = null),
          onDragEnd: (_) => setState(() => _draggingHabitId = null),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.7,
              child: _buildCard(id, name, isChecked, isDragging: true),
            ),
          ),

          childWhenDragging: const SizedBox(width: 0),
          child: _buildCard(
            id,
            name,
            isChecked,
            isDragging: _draggingHabitId == id,
          ),
        );
      },
    );
  }

  Widget _buildCard(
    String id,
    String name,
    bool isChecked, {
    bool isDragging = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      width: 140,
      decoration: BoxDecoration(
        color: isChecked ? Colors.green[300] : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (isChecked)
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          try {
            await _toggleHabit(id);
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
          }
        },
        child: AnimatedScale(
          scale: isChecked ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isChecked ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [const Placeholder(), const StatsPage()];

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
      body: Stack(
        children: [
          _selectedIndex == 0
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
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: habits.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              itemBuilder: (context, index) =>
                                  _buildHabitCard(habits[index]),
                            ),
                          ),
                  ],
                )
              : _pages[_selectedIndex],

          // Zone Drop Poubelle
          Positioned(
            bottom: 16,
            left: 16,
            child: DragTarget<String>(
              onWillAccept: (data) => true,
              onAccept: (id) => _deleteHabit(id),
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isHovering ? Colors.redAccent : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
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

  bool _isValidUuid(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(id);
  }
}

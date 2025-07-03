import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'db/supabase_helper.dart';
import 'stats_page.dart';
import 'style/theme_toggle_slider.dart';
import 'login_page.dart';
import 'notification_service.dart';
import 'notification_service.dart';

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
    Future.microtask(() async {
      if (supabase.auth.currentUser == null && mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        await _loadHabits();
        // Vérifie les rappels au démarrage de l'app
        await NotificationService().checkAndSendReminders();
      }
    });
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
      
      // Récupère la nouvelle habitude pour obtenir son ID
      final habits = await SupabaseHelper.getHabits();
      final newHabit = habits.firstWhere((h) => h['name'] == name);
      
      // Planifie un rappel pour cette habitude dans 24h
      await NotificationService().scheduleHabitReminder(
        habitId: newHabit['id'],
        habitName: name,
        createdDate: DateTime.now(),
      );
      
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
    
    // Si l'habitude vient d'être validée, annule le rappel
    final isNowChecked = await SupabaseHelper.isHabitChecked(id, today);
    if (isNowChecked) {
      await NotificationService().cancelHabitReminder(id);
    }
    
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.secondary.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // En-tête moderne avec titre et actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes Habitudes',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Suivez votre progression quotidienne',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ThemeToggleSlider(
                        width: 50,
                        height: 25,
                        activeColor: Colors.white.withOpacity(0.9),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notification_important, color: Colors.white),
                      tooltip: 'Vérifier les rappels',
                      onPressed: () async {
                        await NotificationService().checkAndSendReminders();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Vérification des rappels terminée ! 🔔'),
                              backgroundColor: theme.colorScheme.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Déconnexion',
                      onPressed: () async {
                        await supabase.auth.signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Contenu principal dans une carte
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _selectedIndex == 0
                      ? _buildHabitsContent(theme)
                      : _buildStatsContent(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Habitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsContent(ThemeData theme) {
    return Stack(
      children: [
        Column(
          children: [
            // Zone d'ajout d'habitude
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter une nouvelle habitude',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Ex: Boire 2L d\'eau, Méditer 10min...',
                            prefixIcon: Icon(
                              Icons.add_task,
                              color: theme.colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant
                                .withOpacity(0.3),
                          ),
                          onSubmitted: (_) => _addHabit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton(
                        onPressed: _addHabit,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        mini: true,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Liste des habitudes
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune habitude ajoutée',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commencez par ajouter votre première habitude !',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        itemCount: habits.length,
                        itemBuilder: (context, index) =>
                            _buildHabitCard(habits[index], theme),
                      ),
                    ),
            ),
          ],
        ),

        // Zone de suppression (poubelle)
        if (_draggingHabitId != null)
          Positioned(
            bottom: 20,
            left: 20,
            child: DragTarget<String>(
              onWillAccept: (data) => true,
              onAccept: (id) {
                _deleteHabit(id);
                setState(() => _draggingHabitId = null);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isHovering
                        ? Colors.red
                        : Colors.red.withOpacity(0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: isHovering ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStatsContent() {
    return const StatsPage();
  }

  Widget _buildHabitCard(Map<String, dynamic> habit, ThemeData theme) {
    final String id = habit['id'] ?? '';
    final String name = habit['name'] ?? 'Sans nom';

    if (!_isValidUuid(id)) return const SizedBox();

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
            child: SizedBox(
              width: 300, // Largeur fixe pour le feedback
              height: 70, // Hauteur fixe pour le feedback
              child: Opacity(
                opacity: 0.8,
                child: _buildCardContent(
                  name,
                  isChecked,
                  theme,
                  isDragging: true,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildCardContent(name, isChecked, theme),
          ),
          child: _buildCardContent(name, isChecked, theme),
        );
      },
    );
  }

  Widget _buildCardContent(
    String name,
    bool isChecked,
    ThemeData theme, {
    bool isDragging = false,
  }) {
    return GestureDetector(
      onTap: isDragging
          ? null
          : () {
              final habit = habits.firstWhere((h) => h['name'] == name);
              _toggleHabit(habit['id']);
            },
      child: Container(
        margin: isDragging
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(
                vertical: 6,
              ), // Pas de marge pendant le drag
        height: 70, // Hauteur fixe pour le format pillule
        decoration: BoxDecoration(
          gradient: isChecked
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.green.shade400, Colors.green.shade600],
                )
              : null,
          color: isChecked ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(
            35,
          ), // Très arrondi pour l'effet pillule
          border: Border.all(
            color: isChecked
                ? Colors.green.shade300
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isChecked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isChecked
                  ? Colors.green.withOpacity(0.3)
                  : theme.shadowColor.withOpacity(0.1),
              blurRadius: isChecked ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ), // Padding horizontal pour pillule
          child: Row(
            children: [
              // Icône à gauche
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isChecked
                      ? Colors.white.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 24,
                  color: isChecked ? Colors.white : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16), // Espacement entre icône et texte
              // Texte au centre
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isChecked
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isChecked
                          ? 'Terminé aujourd\'hui !'
                          : 'À faire aujourd\'hui',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isChecked
                            ? Colors.white.withOpacity(0.8)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicateur de statut à droite
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isChecked
                      ? Colors.white
                      : theme.colorScheme.outline.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
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

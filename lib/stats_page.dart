import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db/supabase_helper.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<Map<String, dynamic>> habits = [];
  Map<String, Map<String, bool>> weeklyStats =
      {}; // habitId -> {date -> isChecked}
  List<DateTime> weekDays = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final fetchedHabits = await SupabaseHelper.getHabits();

      // Calcule les jours de la semaine courante (lundi à dimanche)
      final now = DateTime.now();
      final mondayOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final currentWeekDays = List.generate(
        7,
        (index) => mondayOfWeek.add(Duration(days: index)),
      );

      // Charge les stats pour chaque habitude et chaque jour
      final Map<String, Map<String, bool>> statsMap = {};

      for (final habit in fetchedHabits) {
        final habitId = habit['id'] as String;
        final dailyStats = <String, bool>{};

        for (final day in currentWeekDays) {
          final dateString = DateFormat('yyyy-MM-dd').format(day);
          final isChecked = await SupabaseHelper.isHabitChecked(
            habitId,
            dateString,
          );
          dailyStats[dateString] = isChecked;
        }

        statsMap[habitId] = dailyStats;
      }

      if (mounted) {
        setState(() {
          habits = List<Map<String, dynamic>>.from(fetchedHabits);
          weeklyStats = statsMap;
          weekDays = currentWeekDays;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement stats : $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          habits = [];
          weeklyStats = {};
          weekDays = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (habits.isEmpty) {
      return const Center(child: Text('Aucune habitude trouvée'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suivi hebdomadaire',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildWeeklyTable(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // En-tête avec les jours de la semaine
          _buildTableHeader(),
          // Lignes pour chaque habitude
          ...habits.map((habit) => _buildHabitRow(habit)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // Colonne vide pour les noms d'habitudes
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Habitudes',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Colonnes pour chaque jour
          ...List.generate(7, (index) {
            final day = weekDays[index];
            final isToday = DateUtils.isSameDay(day, DateTime.now());

            return Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    Text(
                      dayNames[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHabitRow(Map<String, dynamic> habit) {
    final habitId = habit['id'] as String;
    final habitName = habit['name'] ?? 'Sans nom';
    final habitStats = weeklyStats[habitId] ?? {};

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Nom de l'habitude
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                habitName,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Cases pour chaque jour
          ...List.generate(7, (index) {
            final day = weekDays[index];
            final dateString = DateFormat('yyyy-MM-dd').format(day);
            final isChecked = habitStats[dateString] ?? false;
            final isToday = DateUtils.isSameDay(day, DateTime.now());

            return Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                  color: isToday
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
                child: Center(
                  child: isChecked
                      ? const Text('✅', style: TextStyle(fontSize: 20))
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

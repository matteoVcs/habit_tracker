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
  Map<String, Map<String, bool>> weeklyStats = {};
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

      setState(() {
        habits = fetchedHabits;
        weeklyStats = statsMap;
        weekDays = currentWeekDays;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des stats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateCompletionRate() {
    if (habits.isEmpty || weeklyStats.isEmpty) return 0.0;

    int totalTasks = 0;
    int completedTasks = 0;

    for (final habit in habits) {
      final habitId = habit['id'] as String;
      final habitStats = weeklyStats[habitId] ?? {};

      for (final isCompleted in habitStats.values) {
        totalTasks++;
        if (isCompleted) completedTasks++;
      }
    }

    return totalTasks > 0 ? completedTasks / totalTasks : 0.0;
  }

  int _getStreakForHabit(String habitId) {
    final habitStats = weeklyStats[habitId] ?? {};
    int streak = 0;

    // Calcule la série en partant d'aujourd'hui et en remontant
    final today = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      if (habitStats[dateString] == true) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des statistiques...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune statistique disponible',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des habitudes pour voir vos progrès !',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    final completionRate = _calculateCompletionRate();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé de la semaine
          _buildWeeklySummaryCard(theme, completionRate),
          const SizedBox(height: 20),

          // Calendrier de la semaine
          _buildWeeklyCalendarCard(theme),
          const SizedBox(height: 20),

          // Statistiques par habitude
          _buildHabitsStatsCard(theme),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(ThemeData theme, double completionRate) {
    final completedHabits = habits.where((habit) {
      final habitId = habit['id'] as String;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      return weeklyStats[habitId]?[today] ?? false;
    }).length;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Résumé de la semaine',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Aujourd\'hui',
                    '$completedHabits/${habits.length}',
                    'habitudes terminées',
                    Colors.white,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Cette semaine',
                    '${(completionRate * 100).toInt()}%',
                    'de réussite',
                    Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barre de progression
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                widthFactor: completionRate,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendarCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendrier de la semaine',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // En-têtes des jours
            Row(
              children: weekDays.map((day) {
                final isToday =
                    DateFormat('yyyy-MM-dd').format(day) ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('E').format(day),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isToday ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // Grille des habitudes
            ...habits.map((habit) => _buildHabitWeekRow(habit, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitWeekRow(Map<String, dynamic> habit, ThemeData theme) {
    final habitId = habit['id'] as String;
    final habitName = habit['name'] as String;
    final habitStats = weeklyStats[habitId] ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            habitName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: weekDays.map((day) {
              final dateString = DateFormat('yyyy-MM-dd').format(day);
              final isChecked = habitStats[dateString] ?? false;
              final isToday =
                  DateFormat('yyyy-MM-dd').format(day) ==
                  DateFormat('yyyy-MM-dd').format(DateTime.now());

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 32,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? Colors.green.shade400
                        : (isToday
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.surfaceVariant.withOpacity(
                                  0.5,
                                )),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isChecked
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsStatsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques par habitude',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...habits.map((habit) => _buildHabitStatRow(habit, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitStatRow(Map<String, dynamic> habit, ThemeData theme) {
    final habitId = habit['id'] as String;
    final habitName = habit['name'] as String;
    final streak = _getStreakForHabit(habitId);
    final habitStats = weeklyStats[habitId] ?? {};
    final weekCompletion = habitStats.values
        .where((completed) => completed)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habitName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Série actuelle: $streak jour${streak > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$weekCompletion/7',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'cette semaine',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await databaseFactoryFfi.getDatabasesPath();
    final path = join(dbPath, 'habits.db');

    return await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE habit_checks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER,
            date TEXT,
            FOREIGN KEY(habit_id) REFERENCES habits(id)
          );
        ''');
      },
    ));
  }

  Future<List<Map<String, dynamic>>> getHabits() async {
    final db = await database;
    return await db.query('habits');
  }

  Future<int> addHabit(String name) async {
    final db = await database;
    return await db.insert('habits', {'name': name});
  }

  Future<void> deleteHabit(int id) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
    await db.delete('habit_checks', where: 'habit_id = ?', whereArgs: [id]);
  }

  Future<void> checkHabit(int habitId, String date) async {
    final db = await database;
    await db.insert('habit_checks', {
      'habit_id': habitId,
      'date': date,
    });
  }

  Future<void> uncheckHabit(int habitId, String date) async {
    final db = await database;
    await db.delete('habit_checks',
        where: 'habit_id = ? AND date = ?', whereArgs: [habitId, date]);
  }

  Future<bool> isHabitChecked(int habitId, String date) async {
    final db = await database;
    final result = await db.query('habit_checks',
        where: 'habit_id = ? AND date = ?', whereArgs: [habitId, date]);
    return result.isNotEmpty;
  }

  Future<int> getWeeklyCheckCount(int habitId) async {
    final db = await database;
    final now = DateTime.now();
    final pastWeek = now.subtract(const Duration(days: 6));
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM habit_checks
      WHERE habit_id = ? AND date BETWEEN ? AND ?
    ''', [
      habitId,
      DateFormat('yyyy-MM-dd').format(pastWeek),
      DateFormat('yyyy-MM-dd').format(now)
    ]);
    return result.first['count'] as int? ?? 0;

  }
}

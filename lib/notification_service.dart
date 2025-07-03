import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart';
import 'db/supabase_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Initialise le timezone
    try {
      tz_data.initializeTimeZones();
    } catch (e) {
      debugPrint('Erreur d\'initialisation timezone: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const macSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Tempo',
      appUserModelId: 'com.klapee.tempo',
      guid: '9970ea82-ea77-44ba-aeb7-6521355f11a2',
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle action if needed
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'klapee_channel',
        'habit_tracker_notification',
        channelDescription: 'General notifications for Klapee apps',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) await init();

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'klapee_channel',
          'habit_tracker_notification',
          channelDescription: 'General notifications for Klapee apps',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      payload: payload,
    );
  }

  /// Planifie un rappel pour une habitude non validée après 24h
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required DateTime createdDate,
  }) async {
    // Calcule la date de rappel (24h après création)
    final reminderTime = createdDate.add(const Duration(hours: 24));
    
    // Génère un ID unique pour cette notification basé sur l'habit ID
    final notificationId = habitId.hashCode.abs() % 2147483647;

    await scheduleNotification(
      id: notificationId,
      title: '🔔 Rappel d\'habitude',
      body: 'N\'oubliez pas de valider votre habitude "$habitName" aujourd\'hui !',
      scheduledTime: reminderTime,
      payload: 'habit_reminder_$habitId',
    );
  }

  /// Annule le rappel d'une habitude (quand elle est validée)
  Future<void> cancelHabitReminder(String habitId) async {
    final notificationId = habitId.hashCode.abs() % 2147483647;
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  /// Vérifie et envoie des rappels pour les habitudes non validées depuis 24h
  Future<void> checkAndSendReminders() async {
    try {
      final habits = await SupabaseHelper.getHabits();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final yesterday = DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(const Duration(days: 1))
      );

      for (final habit in habits) {
        final habitId = habit['id'];
        final habitName = habit['name'] ?? 'Habitude';
        
        // Vérifie si l'habitude a été validée aujourd'hui
        final isCheckedToday = await SupabaseHelper.isHabitChecked(habitId, today);
        
        // Vérifie si l'habitude a été validée hier
        final isCheckedYesterday = await SupabaseHelper.isHabitChecked(habitId, yesterday);
        
        // Si l'habitude n'a pas été validée aujourd'hui ET hier, envoie un rappel
        if (!isCheckedToday && !isCheckedYesterday) {
          await showNotification(
            id: habitId.hashCode.abs() % 2147483647,
            title: '⏰ Rappel important',
            body: 'Vous n\'avez pas validé "$habitName" depuis plus de 24h. Restez motivé !',
            payload: 'habit_reminder_urgent_$habitId',
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des rappels: $e');
    }
  }
}

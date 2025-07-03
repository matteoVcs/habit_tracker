import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialiser les timezones pour les notifications programmées
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const macSettings = DarwinInitializationSettings();
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Ouvrir',
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macSettings,
        linux: linuxSettings,
      );

      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      if (initialized != true) {
        debugPrint('⚠️ Échec de l\'initialisation des notifications');
        return;
      }

      _initialized = true;
      debugPrint('✅ Notifications initialisées avec succès');

      // Demander les permissions sur mobile et programmer les notifications quotidiennes
      if (Platform.isAndroid || Platform.isIOS) {
        await _requestPermissions();
        await scheduleDailyHabitReminder();
      } else {
        debugPrint('ℹ️ Plateforme ${Platform.operatingSystem} - notifications supportées');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification cliquée: ${response.payload}');
    // Ici vous pouvez ajouter une logique pour naviguer vers une page spécifique
    // Par exemple, ouvrir la page des habitudes
  }

  Future<void> _requestPermissions() async {
    // Permissions Android
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
    
    // Permissions iOS
    final iosPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
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
        'habit_tracker_channel',
        'Habit Tracker Notifications',
        channelDescription: 'Notifications pour le suivi des habitudes',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(),
      linux: const LinuxNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Programme une notification quotidienne pour rappeler les habitudes
  Future<void> scheduleDailyHabitReminder() async {
    if (!_initialized) {
      debugPrint('⚠️ Service de notifications non initialisé');
      return;
    }
    
    // Vérifier si on est sur une plateforme supportée pour les notifications programmées
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      debugPrint('ℹ️ Notifications programmées non supportées sur ${Platform.operatingSystem}');
      return;
    }
    
    try {
      // Annuler les notifications précédentes
      await _flutterLocalNotificationsPlugin.cancelAll();
      
      // Configuration pour les différentes plateformes
      const androidDetails = AndroidNotificationDetails(
        'daily_habits_channel',
        'Rappels quotidiens d\'habitudes',
        channelDescription: 'Notifications pour rappeler de vérifier vos habitudes quotidiennes',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      // Programmer pour aujourd'hui à 19h00 (heure de rappel en soirée)
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 19, 0);
      
      // Si c'est déjà passé aujourd'hui, programmer pour demain
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      debugPrint('📅 Notification quotidienne programmée pour: $scheduledDate');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Pense à tes habitudes ! 🎯',
        'Ouvre l\'app et coche ce que tu as fait aujourd\'hui',
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Répéter chaque jour à la même heure
        payload: 'daily_habit_reminder',
      );
      
      debugPrint('✅ Notification quotidienne programmée avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de la programmation de notification: $e');
    }
  }

  /// Envoie une notification de test immédiatement
  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: 'Test de notification 🔔',
      body: 'Si tu vois ça, les notifications fonctionnent parfaitement !',
      payload: 'test_notification',
    );
    debugPrint('✅ Notification de test envoyée');
  }

  /// Vérifie les notifications programmées
  Future<void> checkScheduledNotifications() async {
    if (!_initialized) {
      debugPrint('⚠️ Service de notifications non initialisé pour la vérification');
      return;
    }
    
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('📋 Notifications programmées: ${pendingNotifications.length}');
      for (final notification in pendingNotifications) {
        debugPrint('  - ID: ${notification.id}, Titre: ${notification.title}');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification des notifications: $e');
    }
  }

  /// Annule toutes les notifications programmées
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ Toutes les notifications ont été annulées');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation des notifications: $e');
    }
  }

  /// Annule une notification spécifique
  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('✅ Notification $id annulée');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation de la notification $id: $e');
    }
  }
}
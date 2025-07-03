import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static bool _isInitialized = false;
  
  static Future<void> init() async {
    try {
      // Initialiser les timezones
      tz.initializeTimeZones();
      
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Configuration Windows (limitée)
      const windows = DarwinInitializationSettings();

      const settings = InitializationSettings(
        android: android, 
        iOS: ios,
        macOS: windows,  // Utiliser les paramètres macOS pour Windows
      );
      
      // Attendre que l'initialisation soit complète
      final initialized = await flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification cliquée: ${response.payload}');
        },
      );

      if (initialized != true) {
        print('⚠️ Échec de l\'initialisation des notifications');
        return;
      }

      _isInitialized = true;
      print('✅ Notifications initialisées avec succès');

      // Demander les permissions seulement sur mobile
      if (Platform.isAndroid || Platform.isIOS) {
        await _requestPermissions();
        // Programmer la notification quotidienne seulement sur mobile
        await scheduleDailyNotification();
      } else {
        print('ℹ️ Plateforme ${Platform.operatingSystem} - notifications limitées');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
    
    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> scheduleDailyNotification() async {
    if (!_isInitialized) {
      print('⚠️ Service de notifications non initialisé');
      return;
    }
    
    // Vérifier si on est sur une plateforme supportée
    if (!Platform.isAndroid && !Platform.isIOS) {
      print('ℹ️ Notifications planifiées non supportées sur ${Platform.operatingSystem}');
      return;
    }
    
    try {
      // Annuler les notifications précédentes (seulement si le plugin est initialisé)
      await flutterLocalNotificationsPlugin.cancelAll();
      
      // Configuration pour Android
      const androidDetails = AndroidNotificationDetails(
        'daily_habits_channel',
        'Rappels quotidiens d\'habitudes',
        channelDescription: 'Notifications pour rappeler de vérifier vos habitudes',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      // Configuration pour iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Programmer pour aujourd'hui à 12h05
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 12, 5);
      
      // Si c'est déjà passé aujourd'hui, programmer pour demain
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      print('📅 Notification programmée pour: $scheduledDate');

      await flutterLocalNotificationsPlugin.zonedSchedule(
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
      
      print('✅ Notification quotidienne programmée avec succès');
    } catch (e) {
      print('❌ Erreur lors de la programmation de notification: $e');
    }
  }

  // Méthode pour tester immédiatement
  static Future<void> showTestNotification() async {
    if (!_isInitialized) {
      print('⚠️ Service de notifications non initialisé pour le test');
      return;
    }
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test',
        channelDescription: 'Notification de test',
        importance: Importance.max,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        999,
        'Test de notification 🔔',
        'Si tu vois ça, les notifications fonctionnent !',
        notificationDetails,
      );
      
      print('✅ Notification de test envoyée');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la notification de test: $e');
    }
  }

  // Vérifier les notifications programmées
  static Future<void> checkScheduledNotifications() async {
    if (!_isInitialized) {
      print('⚠️ Service de notifications non initialisé pour la vérification');
      return;
    }
    
    // Vérifier si on est sur une plateforme supportée
    if (!Platform.isAndroid && !Platform.isIOS) {
      print('ℹ️ Vérification des notifications non supportée sur ${Platform.operatingSystem}');
      return;
    }
    
    try {
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('📋 Notifications programmées: ${pendingNotifications.length}');
      for (final notification in pendingNotifications) {
        print('  - ID: ${notification.id}, Titre: ${notification.title}');
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification des notifications: $e');
    }
  }
}

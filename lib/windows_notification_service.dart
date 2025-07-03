import 'dart:io';

class WindowsNotificationService {
  static Future<void> init() async {
    if (Platform.isWindows) {
      print('✅ Service de notifications Windows initialisé');

      // Programmer la notification quotidienne
      await _scheduleWindowsNotification();
    } else {
      print(
        'ℹ️ Service de notifications Windows non applicable sur ${Platform.operatingSystem}',
      );
    }
  }

  // Afficher une notification immédiate via PowerShell
  static Future<void> showTestNotification() async {
    if (!Platform.isWindows) {
      print(
        'ℹ️ Notifications Windows non disponibles sur ${Platform.operatingSystem}',
      );
      return;
    }

    try {
      // Commande PowerShell pour afficher une vraie notification toast Windows
      final result = await Process.run('powershell.exe', [
        '-Command',
        '''
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > \$null

        \$APP_ID = "Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"

        \$template = @"
        <toast>
            <visual>
                <binding template="ToastGeneric">
                    <text>Habit Tracker 🎯</text>
                    <text>Test de notification réussi ! Les notifications Windows fonctionnent parfaitement.</text>
                </binding>
            </visual>
            <actions>
                <action content="OK" arguments="ok" />
            </actions>
        </toast>
"@

        \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        \$xml.LoadXml(\$template)
        \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$APP_ID).Show(\$toast)
        ''',
      ]);

      if (result.exitCode == 0) {
        print('✅ Notification toast Windows affichée avec succès');
      } else {
        print(
          '❌ Erreur lors de l\'affichage de la notification: ${result.stderr}',
        );
        // Fallback vers une notification plus simple
        await _showSimpleNotification();
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la notification Windows: $e');
      await _showSimpleNotification();
    }
  }

  // Fallback pour une notification plus simple
  static Future<void> _showSimpleNotification() async {
    try {
      final result = await Process.run('powershell.exe', [
        '-Command',
        '''
        Add-Type -AssemblyName System.Windows.Forms
        \$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        \$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
        \$notifyIcon.Visible = \$true
        \$notifyIcon.ShowBalloonTip(5000, "Habit Tracker 🎯", "Test de notification réussi !", [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep -Seconds 6
        \$notifyIcon.Dispose()
        ''',
      ]);

      if (result.exitCode == 0) {
        print('✅ Notification bulle Windows affichée avec succès');
      } else {
        print('❌ Impossible d\'afficher la notification: ${result.stderr}');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'affichage de la notification simple: $e');
    }
  }

  // Programmer une notification quotidienne via le planificateur de tâches Windows
  static Future<void> _scheduleWindowsNotification() async {
    if (!Platform.isWindows) return;

    try {
      // Créer un script PowerShell pour la notification quotidienne
      final scriptPath = await _createNotificationScript();

      // Créer une tâche planifiée Windows
      final result = await Process.run('schtasks.exe', [
        '/Create',
        '/TN', 'HabitTrackerReminder',
        '/TR', 'powershell.exe -WindowStyle Hidden -File "$scriptPath"',
        '/SC', 'DAILY',
        '/ST', '12:05',
        '/F', // Force la création même si la tâche existe déjà
      ]);

      if (result.exitCode == 0) {
        print('✅ Notification quotidienne programmée avec succès à 12h05');
      } else {
        print(
          '⚠️ Impossible de programmer la notification quotidienne: ${result.stderr}',
        );
        print('ℹ️ Les notifications de test fonctionnent toujours');
      }
    } catch (e) {
      print('❌ Erreur lors de la programmation de la notification: $e');
    }
  }

  // Créer un script PowerShell pour les notifications
  static Future<String> _createNotificationScript() async {
    final tempDir = Directory.systemTemp;
    final scriptFile = File('${tempDir.path}\\habit_tracker_notification.ps1');

    final scriptContent = '''
# Script de notification toast pour Habit Tracker
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > \$null

    \$APP_ID = "Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"

    \$template = @"
    <toast>
        <visual>
            <binding template="ToastGeneric">
                <text>Habit Tracker 🎯</text>
                <text>Pense à vérifier tes habitudes quotidiennes !</text>
            </binding>
        </visual>
        <actions>
            <action content="Ouvrir l'app" arguments="open" />
            <action content="Plus tard" arguments="later" />
        </actions>
    </toast>
"@

    \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    \$xml.LoadXml(\$template)
    \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\$APP_ID).Show(\$toast)
    
    Write-Host "✅ Notification toast envoyée avec succès"
    
} catch {
    # Fallback vers notification bulle si toast échoue
    try {
        Add-Type -AssemblyName System.Windows.Forms
        \$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
        \$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
        \$notifyIcon.Visible = \$true
        \$notifyIcon.ShowBalloonTip(5000, "Habit Tracker 🎯", "Pense à vérifier tes habitudes quotidiennes !", [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep -Seconds 6
        \$notifyIcon.Dispose()
        
        Write-Host "✅ Notification bulle envoyée avec succès"
    } catch {
        Write-Host "❌ Impossible d'envoyer la notification: \$_"
    }
}
''';

    await scriptFile.writeAsString(scriptContent);
    return scriptFile.path;
  }

  // Vérifier les notifications programmées
  static Future<void> checkScheduledNotifications() async {
    if (!Platform.isWindows) {
      print(
        'ℹ️ Vérification des notifications non applicable sur ${Platform.operatingSystem}',
      );
      return;
    }

    try {
      final result = await Process.run('schtasks.exe', [
        '/Query',
        '/TN',
        'HabitTrackerReminder',
        '/FO',
        'LIST',
      ]);

      if (result.exitCode == 0) {
        print('📋 Tâche de notification trouvée:');
        print(result.stdout);
      } else {
        print('ℹ️ Aucune tâche de notification programmée');
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification des notifications: $e');
    }
  }

  // Supprimer la tâche programmée
  static Future<void> cancelScheduledNotifications() async {
    if (!Platform.isWindows) return;

    try {
      final result = await Process.run('schtasks.exe', [
        '/Delete',
        '/TN',
        'HabitTrackerReminder',
        '/F',
      ]);

      if (result.exitCode == 0) {
        print('✅ Tâche de notification supprimée');
      } else {
        print('ℹ️ Aucune tâche de notification à supprimer');
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression de la tâche: $e');
    }
  }
}

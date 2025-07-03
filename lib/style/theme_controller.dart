import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  void toggleTheme() {
    // Si on est en mode système, commence par passer au mode opposé
    if (value == ThemeMode.system) {
      // Détecte le thème système actuel et bascule vers l'opposé
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      value = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      // Bascule entre clair et sombre
      value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
  }
}

final themeController = ThemeController();

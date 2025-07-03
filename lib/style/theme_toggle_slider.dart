import 'package:flutter/material.dart';
import 'theme_controller.dart';

class ThemeToggleSlider extends StatelessWidget {
  final double width;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const ThemeToggleSlider({
    super.key,
    this.width = 60,
    this.height = 30,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effectiveActiveColor = activeColor ?? theme.colorScheme.primary;
    final effectiveInactiveColor = inactiveColor ?? theme.colorScheme.outline;
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surfaceVariant;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, themeMode, child) {
        // Détermine si le thème actuel est sombre
        bool isOn;
        if (themeMode == ThemeMode.system) {
          // Si le mode est système, vérifie le thème actuel du contexte
          isOn = theme.brightness == Brightness.dark;
        } else {
          // Sinon, utilise directement la valeur du contrôleur
          isOn = themeMode == ThemeMode.dark;
        }

        return GestureDetector(
          onTap: () => themeController.toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: isOn ? effectiveActiveColor : effectiveBackgroundColor,
              border: Border.all(
                color: isOn ? effectiveActiveColor : effectiveInactiveColor,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  top: 2,
                  left: isOn ? width - height + 2 : 2,
                  child: Container(
                    width: height - 4,
                    height: height - 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isOn ? Icons.nightlight_round : Icons.wb_sunny,
                          key: ValueKey(isOn),
                          size: 14,
                          color: isOn
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFFFA726),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'accessibility_widgets.dart';

/// Widget para seleccionar el tema de la aplicación
class ThemeSelector extends StatelessWidget {
  final bool showAsDialog;
  final String? title;

  const ThemeSelector({
    super.key,
    this.showAsDialog = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (showAsDialog) {
      return _ThemeSelectorDialog(title: title);
    } else {
      return _ThemeSelectorList(title: title);
    }
  }

  /// Mostrar selector de tema como diálogo
  static Future<void> showDialog(BuildContext context, {String? title}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ThemeSelector(
        showAsDialog: true,
        title: title,
      ),
    );
  }
}

class _ThemeSelectorDialog extends StatelessWidget {
  final String? title;

  const _ThemeSelectorDialog({this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle del modal
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Título
          Text(
            title ?? 'Seleccionar tema',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          
          // Lista de opciones
          const _ThemeSelectorList(showTitle: false),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ThemeSelectorList extends StatelessWidget {
  final String? title;
  final bool showTitle;

  const _ThemeSelectorList({
    this.title,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final availableThemes = themeService.getAvailableThemes();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle) ...[
              Text(
                title ?? 'Tema',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
            ],
            
            ...availableThemes.map((themeOption) {
              final isSelected = themeService.themeMode == themeOption.mode;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AccessibleListTile(
                  leading: Icon(
                    themeOption.icon,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : null,
                  ),
                  title: Text(
                    themeOption.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : null,
                    ),
                  ),
                  subtitle: Text(themeOption.description),
                  trailing: isSelected 
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  semanticLabel: '${themeOption.name}: ${themeOption.description}${isSelected ? ', seleccionado' : ''}',
                  onTap: () async {
                    await themeService.setTheme(themeOption.mode);
                    
                    // Mostrar feedback
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tema cambiado a ${themeOption.name}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

/// Widget simple para alternar tema (botón)
class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final String? tooltip;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return AccessibleButton(
          onPressed: () => themeService.toggleTheme(),
          semanticLabel: 'Cambiar tema a ${themeService.isDarkMode ? 'claro' : 'oscuro'}',
          tooltip: tooltip ?? 'Cambiar tema',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(themeService.getThemeIcon()),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(themeService.getThemeName()),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Widget para mostrar el tema actual como chip
class CurrentThemeChip extends StatelessWidget {
  final VoidCallback? onTap;

  const CurrentThemeChip({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return ActionChip(
          avatar: Icon(
            themeService.getThemeIcon(),
            size: 18,
          ),
          label: Text(themeService.getThemeName()),
          onPressed: onTap ?? () => ThemeSelector.showDialog(context),
          tooltip: 'Cambiar tema',
        );
      },
    );
  }
}

/// Widget para configuración avanzada de tema
class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración de tema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Selector de tema principal
            const _ThemeSelectorList(),
            
            const SizedBox(height: 24),
            
            // Información adicional
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El tema "Sistema" cambiará automáticamente según la configuración de tu dispositivo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    
                    // Estadísticas del tema
                    _buildThemeStats(context, themeService),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón para resetear
            Center(
              child: AccessibleButton(
                onPressed: () async {
                  await themeService.resetToDefault();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tema restablecido a configuración por defecto'),
                      ),
                    );
                  }
                },
                semanticLabel: 'Restablecer tema a configuración por defecto',
                child: const Text('Restablecer por defecto'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeStats(BuildContext context, ThemeService themeService) {
    final stats = themeService.getThemeStats();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatRow(context, 'Tema actual:', stats['currentTheme']),
        _buildStatRow(context, 'Sigue sistema:', stats['followSystemTheme'] ? 'Sí' : 'No'),
        _buildStatRow(context, 'Modo oscuro:', stats['isDarkMode'] ? 'Activo' : 'Inactivo'),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

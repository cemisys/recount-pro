import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import 'accessibility_widgets.dart';

/// Widget para seleccionar el idioma de la aplicación
class LanguageSelector extends StatelessWidget {
  final bool showAsDialog;
  final String? title;

  const LanguageSelector({
    super.key,
    this.showAsDialog = false,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (showAsDialog) {
      return _LanguageSelectorDialog(title: title);
    } else {
      return _LanguageSelectorList(title: title);
    }
  }

  /// Mostrar selector de idioma como diálogo
  static Future<void> showDialog(BuildContext context, {String? title}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LanguageSelector(
        showAsDialog: true,
        title: title,
      ),
    );
  }
}

class _LanguageSelectorDialog extends StatelessWidget {
  final String? title;

  const _LanguageSelectorDialog({this.title});

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
            title ?? 'Seleccionar idioma',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          
          // Lista de opciones
          const _LanguageSelectorList(showTitle: false),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _LanguageSelectorList extends StatelessWidget {
  final String? title;
  final bool showTitle;

  const _LanguageSelectorList({
    this.title,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        final availableLanguages = localizationService.getAvailableLanguages();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle) ...[
              Text(
                title ?? 'Idioma',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
            ],
            
            ...availableLanguages.map((languageOption) {
              final isSelected = localizationService.currentLocale == languageOption.locale;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AccessibleListTile(
                  leading: Text(
                    languageOption.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    languageOption.nativeName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : null,
                    ),
                  ),
                  subtitle: Text(languageOption.name),
                  trailing: isSelected 
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  semanticLabel: '${languageOption.nativeName}: ${languageOption.name}${isSelected ? ', seleccionado' : ''}',
                  onTap: () async {
                    await localizationService.setLocale(languageOption.locale);
                    
                    // Mostrar feedback
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Idioma cambiado a ${languageOption.nativeName}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
            
            const SizedBox(height: 16),
            
            // Opción para seguir el sistema
            AccessibleListTile(
              leading: const Icon(Icons.settings_system_daydream),
              title: Text(
                'Seguir sistema',
                style: TextStyle(
                  fontWeight: localizationService.followSystemLocale ? FontWeight.w600 : FontWeight.normal,
                  color: localizationService.followSystemLocale 
                      ? Theme.of(context).colorScheme.primary 
                      : null,
                ),
              ),
              subtitle: const Text('Usar idioma del dispositivo'),
              trailing: localizationService.followSystemLocale 
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              selected: localizationService.followSystemLocale,
              semanticLabel: 'Seguir idioma del sistema${localizationService.followSystemLocale ? ', seleccionado' : ''}',
              onTap: () async {
                await localizationService.setSystemLocale();
                
                // Mostrar feedback
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configurado para seguir el idioma del sistema'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

/// Widget simple para alternar idioma (botón)
class LanguageToggleButton extends StatelessWidget {
  final bool showLabel;
  final String? tooltip;

  const LanguageToggleButton({
    super.key,
    this.showLabel = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return AccessibleButton(
          onPressed: () => localizationService.toggleLanguage(),
          semanticLabel: 'Cambiar idioma a ${localizationService.isSpanish ? 'inglés' : 'español'}',
          tooltip: tooltip ?? 'Cambiar idioma',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizationService.getCurrentLanguageFlag(),
                style: const TextStyle(fontSize: 20),
              ),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(localizationService.getCurrentLanguageLocalizedName()),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Widget para mostrar el idioma actual como chip
class CurrentLanguageChip extends StatelessWidget {
  final VoidCallback? onTap;

  const CurrentLanguageChip({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return ActionChip(
          avatar: Text(
            localizationService.getCurrentLanguageFlag(),
            style: const TextStyle(fontSize: 16),
          ),
          label: Text(localizationService.getCurrentLanguageLocalizedName()),
          onPressed: onTap ?? () => LanguageSelector.showDialog(context),
          tooltip: 'Cambiar idioma',
        );
      },
    );
  }
}

/// Widget para configuración avanzada de idioma
class LanguageSettings extends StatelessWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración de idioma',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Selector de idioma principal
            const _LanguageSelectorList(),
            
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
                      'La opción "Seguir sistema" cambiará automáticamente el idioma según la configuración de tu dispositivo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    
                    // Estadísticas del idioma
                    _buildLanguageStats(context, localizationService),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón para resetear
            Center(
              child: AccessibleButton(
                onPressed: () async {
                  await localizationService.resetToDefault();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Idioma restablecido a configuración por defecto'),
                      ),
                    );
                  }
                },
                semanticLabel: 'Restablecer idioma a configuración por defecto',
                child: const Text('Restablecer por defecto'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageStats(BuildContext context, LocalizationService localizationService) {
    final stats = localizationService.getLocalizationStats();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatRow(context, 'Idioma actual:', stats['current_locale']),
        _buildStatRow(context, 'Sigue sistema:', stats['follow_system_locale'] ? 'Sí' : 'No'),
        _buildStatRow(context, 'Es español:', stats['is_spanish'] ? 'Sí' : 'No'),
        _buildStatRow(context, 'Es inglés:', stats['is_english'] ? 'Sí' : 'No'),
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

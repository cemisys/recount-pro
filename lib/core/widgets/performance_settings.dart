import 'package:flutter/material.dart';
import '../services/performance_service.dart';
import 'accessibility_widgets.dart';

/// Widget para configurar las opciones de performance
class PerformanceSettings extends StatefulWidget {
  const PerformanceSettings({super.key});

  @override
  State<PerformanceSettings> createState() => _PerformanceSettingsState();
}

class _PerformanceSettingsState extends State<PerformanceSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración de Rendimiento',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        // Calidad de imagen
        _buildImageQualitySection(),
        
        const SizedBox(height: 24),
        
        // Configuraciones generales
        _buildGeneralSettingsSection(),
        
        const SizedBox(height: 24),
        
        // Modo de bajo consumo
        _buildLowMemorySection(),
        
        const SizedBox(height: 24),
        
        // Información y estadísticas
        _buildStatsSection(),
        
        const SizedBox(height: 16),
        
        // Acciones
        _buildActionsSection(),
      ],
    );
  }

  Widget _buildImageQualitySection() {
    return AccessibleCard(
      semanticLabel: 'Configuración de calidad de imagen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calidad de Imagen',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta la calidad de las imágenes para optimizar el rendimiento y el uso de memoria.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          ...ImageQuality.values.map((quality) {
            return RadioListTile<ImageQuality>(
              title: Text(quality.displayName),
              subtitle: Text(_getImageQualityDescription(quality)),
              value: quality,
              groupValue: PerformanceService.imageQuality,
              onChanged: (value) async {
                if (value != null) {
                  await PerformanceService.setImageQuality(value);
                  setState(() {});
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calidad de imagen cambiada a ${value.displayName}'),
                      ),
                    );
                  }
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGeneralSettingsSection() {
    return AccessibleCard(
      semanticLabel: 'Configuraciones generales de rendimiento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuraciones Generales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          AccessibleListTile(
            leading: const Icon(Icons.animation),
            title: const Text('Animaciones'),
            subtitle: const Text('Habilitar animaciones y transiciones'),
            trailing: Switch(
              value: PerformanceService.animationsEnabled,
              onChanged: (value) async {
                await PerformanceService.setAnimationsEnabled(value);
                setState(() {});
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Animaciones ${value ? 'habilitadas' : 'deshabilitadas'}'),
                    ),
                  );
                }
              },
            ),
            semanticLabel: 'Activar o desactivar animaciones',
          ),
          
          AccessibleListTile(
            leading: const Icon(Icons.download),
            title: const Text('Precarga de Datos'),
            subtitle: const Text('Cargar datos por adelantado para mejor rendimiento'),
            trailing: Switch(
              value: PerformanceService.preloadData,
              onChanged: (value) async {
                await PerformanceService.setPreloadData(value);
                setState(() {});
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Precarga de datos ${value ? 'habilitada' : 'deshabilitada'}'),
                    ),
                  );
                }
              },
            ),
            semanticLabel: 'Activar o desactivar precarga de datos',
          ),
        ],
      ),
    );
  }

  Widget _buildLowMemorySection() {
    return AccessibleCard(
      semanticLabel: 'Configuración de modo de bajo consumo de memoria',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory,
                color: PerformanceService.lowMemoryMode 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Modo de Bajo Consumo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Optimiza la aplicación para dispositivos con poca memoria disponible.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          AccessibleListTile(
            leading: Icon(
              PerformanceService.lowMemoryMode ? Icons.memory : Icons.memory_outlined,
              color: PerformanceService.lowMemoryMode 
                  ? Theme.of(context).colorScheme.primary 
                  : null,
            ),
            title: Text(
              'Activar Modo de Bajo Consumo',
              style: TextStyle(
                fontWeight: PerformanceService.lowMemoryMode ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              PerformanceService.lowMemoryMode 
                  ? 'Activo - Optimizaciones aplicadas'
                  : 'Inactivo - Rendimiento normal',
            ),
            trailing: Switch(
              value: PerformanceService.lowMemoryMode,
              onChanged: (value) async {
                await PerformanceService.setLowMemoryMode(value);
                setState(() {});
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Modo de bajo consumo ${value ? 'activado' : 'desactivado'}'),
                    ),
                  );
                }
              },
            ),
            semanticLabel: 'Activar o desactivar modo de bajo consumo de memoria',
          ),
          
          if (PerformanceService.lowMemoryMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Optimizaciones activas: Calidad de imagen reducida, animaciones deshabilitadas, precarga desactivada.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = PerformanceService.getPerformanceStats();
    
    return AccessibleCard(
      semanticLabel: 'Estadísticas de rendimiento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas de Rendimiento',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          _buildStatRow('Calidad de imagen:', stats['image_quality']),
          _buildStatRow('Factor de escala:', '${(stats['image_scale_factor'] * 100).toInt()}%'),
          _buildStatRow('Caché de imágenes:', '${stats['image_cache_size_mb']} MB'),
          _buildStatRow('Animaciones:', stats['animations_enabled'] ? 'Habilitadas' : 'Deshabilitadas'),
          _buildStatRow('Precarga de datos:', stats['preload_data'] ? 'Habilitada' : 'Deshabilitada'),
          _buildStatRow('Modo bajo consumo:', stats['low_memory_mode'] ? 'Activo' : 'Inactivo'),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return AccessibleCard(
      semanticLabel: 'Acciones de rendimiento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          AccessibleListTile(
            leading: const Icon(Icons.auto_fix_high),
            title: const Text('Aplicar Configuración Recomendada'),
            subtitle: const Text('Optimizar automáticamente según el dispositivo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await PerformanceService.applyRecommendedSettings();
              setState(() {});
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración recomendada aplicada'),
                  ),
                );
              }
            },
            semanticLabel: 'Aplicar configuración de rendimiento recomendada',
          ),
          
          AccessibleListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Limpiar Caché de Imágenes'),
            subtitle: const Text('Liberar memoria utilizada por imágenes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await PerformanceService.clearImageCache();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Caché de imágenes limpiado'),
                  ),
                );
              }
            },
            semanticLabel: 'Limpiar caché de imágenes',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getImageQualityDescription(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 'Menor calidad, menor uso de memoria';
      case ImageQuality.medium:
        return 'Calidad balanceada';
      case ImageQuality.high:
        return 'Máxima calidad, mayor uso de memoria';
    }
  }
}

/// Widget compacto para mostrar estado de performance
class PerformanceStatusWidget extends StatelessWidget {
  const PerformanceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PerformanceService.lowMemoryMode 
                  ? Icons.memory 
                  : Icons.speed,
              size: 16,
              color: PerformanceService.lowMemoryMode 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              PerformanceService.lowMemoryMode 
                  ? 'Modo Optimizado'
                  : 'Rendimiento Normal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/metrics_service.dart';
import '../../core/services/update_service.dart';
import '../../core/widgets/theme_selector.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/metrics_dashboard.dart';
import '../../core/widgets/performance_settings.dart';
import '../../core/widgets/accessibility_widgets.dart';

/// Pantalla de configuración de la aplicación
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _autoUpdateEnabled = true; // Estado de verificación automática

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAutoUpdatePreference();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.settings),
              text: 'General',
            ),
            Tab(
              icon: Icon(Icons.palette),
              text: 'Tema',
            ),
            Tab(
              icon: Icon(Icons.language),
              text: 'Idioma',
            ),
            Tab(
              icon: Icon(Icons.speed),
              text: 'Rendimiento',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Métricas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralSettings(),
          _buildThemeSettings(),
          _buildLanguageSettings(),
          _buildPerformanceSettings(),
          _buildMetricsSettings(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AccessibleCard(
          semanticLabel: 'Configuración de la aplicación',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aplicación',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              const AccessibleListTile(
                leading: Icon(Icons.info),
                title: Text('Versión'),
                subtitle: Text('1.0.0'),
                semanticLabel: 'Versión de la aplicación: 1.0.0',
              ),
              
              AccessibleListTile(
                leading: const Icon(Icons.update),
                title: const Text('Buscar actualizaciones'),
                subtitle: const Text('Última verificación: Hoy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _checkForUpdates(),
                semanticLabel: 'Buscar actualizaciones de la aplicación',
              ),

              AccessibleListTile(
                leading: const Icon(Icons.auto_mode),
                title: const Text('Verificación automática'),
                subtitle: Text(_autoUpdateEnabled
                    ? 'Verificar actualizaciones al iniciar la app'
                    : 'Verificación automática deshabilitada'),
                trailing: Switch(
                  value: _autoUpdateEnabled,
                  onChanged: (value) => _saveAutoUpdatePreference(value),
                ),
                onTap: () => _saveAutoUpdatePreference(!_autoUpdateEnabled),
                semanticLabel: 'Habilitar o deshabilitar verificación automática de actualizaciones',
              ),
              
              AccessibleListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Limpiar caché'),
                subtitle: const Text('Liberar espacio de almacenamiento'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _clearCache(),
                semanticLabel: 'Limpiar caché de la aplicación',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        AccessibleCard(
          semanticLabel: 'Configuración de datos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              AccessibleListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Sincronización automática'),
                subtitle: const Text('Sincronizar datos en segundo plano'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) => _toggleAutoSync(value),
                ),
                semanticLabel: 'Activar sincronización automática de datos',
              ),
              
              AccessibleListTile(
                leading: const Icon(Icons.wifi_off),
                title: const Text('Modo offline'),
                subtitle: const Text('Trabajar sin conexión a internet'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) => _toggleOfflineMode(value),
                ),
                semanticLabel: 'Activar modo offline',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSettings() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: ThemeSettings(),
    );
  }

  Widget _buildLanguageSettings() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: LanguageSettings(),
    );
  }

  Widget _buildPerformanceSettings() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: PerformanceSettings(),
    );
  }

  Widget _buildMetricsSettings() {
    return Consumer<MetricsService>(
      builder: (context, metricsService, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Dashboard de métricas
            const MetricsDashboard(),
            
            const SizedBox(height: 24),
            
            // Configuración de métricas
            AccessibleCard(
              semanticLabel: 'Configuración de métricas',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración de Métricas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AccessibleListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Recopilar métricas'),
                    subtitle: const Text('Ayuda a mejorar la aplicación'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) => _toggleMetricsCollection(value),
                    ),
                    semanticLabel: 'Activar recopilación de métricas',
                  ),
                  
                  AccessibleListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Reportes de errores'),
                    subtitle: const Text('Enviar reportes automáticamente'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) => _toggleErrorReporting(value),
                    ),
                    semanticLabel: 'Activar reportes automáticos de errores',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Acciones de métricas
            AccessibleCard(
              semanticLabel: 'Acciones de métricas',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acciones',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  AccessibleListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text('Exportar métricas'),
                    subtitle: const Text('Descargar datos de uso'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportMetrics(metricsService),
                    semanticLabel: 'Exportar métricas de uso',
                  ),
                  
                  AccessibleListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Reiniciar métricas'),
                    subtitle: const Text('Borrar todos los datos de métricas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _resetMetrics(metricsService),
                    semanticLabel: 'Reiniciar todas las métricas',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Métodos de configuración general
  void _checkForUpdates() async {
    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Verificando actualizaciones...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final updateInfo = await UpdateService.checkForUpdates();

      if (mounted) {
        // Ocultar snackbar de carga
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (updateInfo.hasError) {
          // Error al verificar
          _showErrorDialog(updateInfo.error!);
        } else if (updateInfo.hasUpdate) {
          // Hay actualización disponible
          _showUpdateDialog(updateInfo);
        } else {
          // No hay actualizaciones
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✅ Tu aplicación está actualizada'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorDialog(e.toString());
      }
    }
  }

  /// Cargar preferencia de verificación automática
  Future<void> _loadAutoUpdatePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _autoUpdateEnabled = prefs.getBool('auto_update_enabled') ?? true;
      });
    } catch (e) {
      print('Error cargando preferencia de auto-update: $e');
    }
  }

  /// Guardar preferencia de verificación automática
  Future<void> _saveAutoUpdatePreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_update_enabled', enabled);
      setState(() {
        _autoUpdateEnabled = enabled;
      });
    } catch (e) {
      print('Error guardando preferencia de auto-update: $e');
    }
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar caché'),
        content: const Text('¿Estás seguro de que quieres limpiar el caché? Esto puede afectar el rendimiento temporalmente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caché limpiado exitosamente')),
              );
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _toggleAutoSync(bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Sincronización automática activada' : 'Sincronización automática desactivada'),
      ),
    );
  }

  void _toggleOfflineMode(bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Modo offline activado' : 'Modo offline desactivado'),
      ),
    );
  }

  // Métodos de configuración de métricas
  void _toggleMetricsCollection(bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Recopilación de métricas activada' : 'Recopilación de métricas desactivada'),
      ),
    );
  }

  void _toggleErrorReporting(bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Reportes de errores activados' : 'Reportes de errores desactivados'),
      ),
    );
  }

  void _exportMetrics(MetricsService metricsService) {
    final metrics = metricsService.exportMetrics();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar métricas'),
        content: SingleChildScrollView(
          child: Text(
            'Métricas exportadas:\n\n${metrics.toString()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _resetMetrics(MetricsService metricsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar métricas'),
        content: const Text('¿Estás seguro de que quieres borrar todas las métricas? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await metricsService.resetMetrics();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Métricas reiniciadas exitosamente')),
                );
              }
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de actualización disponible
  void _showUpdateDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate, // No se puede cerrar si es forzada
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              updateInfo.isForceUpdate ? Icons.warning : Icons.update,
              color: updateInfo.isForceUpdate ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(updateInfo.isForceUpdate ? 'Actualización Requerida' : 'Actualización Disponible'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                updateInfo.updateMessage,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Información de versiones
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Versión actual:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(updateInfo.currentVersion),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nueva versión:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          updateInfo.latestVersion,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Changelog si está disponible
              if (updateInfo.changelog.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Novedades:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    updateInfo.changelog,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Botón "Más tarde" solo si no es actualización forzada
          if (!updateInfo.isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Más tarde'),
            ),

          // Botón de actualizar
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              UpdateService.openUpdateUrl(updateInfo.updateUrl);
            },
            icon: const Icon(Icons.download),
            label: Text(updateInfo.isForceUpdate ? 'Actualizar Ahora' : 'Descargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: updateInfo.isForceUpdate ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de error
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error de Actualización'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No se pudo verificar si hay actualizaciones disponibles.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Error: $error',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkForUpdates(); // Reintentar
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

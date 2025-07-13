import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../services/update_preferences_service.dart';

/// Widget que verifica automáticamente actualizaciones al iniciar la app
class AutoUpdateChecker extends StatefulWidget {
  final Widget child;
  final bool enableAutoCheck;
  final Duration delayBeforeCheck;
  final bool showOnlyForceUpdates;

  const AutoUpdateChecker({
    super.key,
    required this.child,
    this.enableAutoCheck = true,
    this.delayBeforeCheck = const Duration(seconds: 3),
    this.showOnlyForceUpdates = false,
  });

  @override
  State<AutoUpdateChecker> createState() => _AutoUpdateCheckerState();
}

class _AutoUpdateCheckerState extends State<AutoUpdateChecker> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableAutoCheck) {
      _scheduleUpdateCheck();
    }
  }

  /// Programar verificación de actualización después del delay
  void _scheduleUpdateCheck() {
    Future.delayed(widget.delayBeforeCheck, () {
      if (mounted && !_hasChecked) {
        _checkForUpdates();
      }
    });
  }

  /// Verificar actualizaciones automáticamente
  Future<void> _checkForUpdates() async {
    if (_hasChecked) return;

    try {
      print('🔄 [AUTO_UPDATE] Verificando actualizaciones automáticamente...');
      _hasChecked = true;

      // 1. Verificar si la verificación automática está habilitada
      final autoUpdateEnabled = await UpdatePreferencesService.isAutoUpdateEnabled();
      if (!autoUpdateEnabled) {
        print('⚠️ [AUTO_UPDATE] Verificación automática deshabilitada por el usuario');
        return;
      }

      // 2. Verificar cooldown para evitar spam
      final shouldCheck = await UpdatePreferencesService.shouldCheckForUpdates(
        cooldown: const Duration(hours: 6), // Verificar máximo cada 6 horas
      );
      if (!shouldCheck) {
        print('⚠️ [AUTO_UPDATE] Muy pronto para verificar actualizaciones');
        return;
      }

      // 3. Verificar actualizaciones
      final updateInfo = await UpdateService.checkForUpdates();

      // 4. Guardar timestamp de verificación
      await UpdatePreferencesService.setLastUpdateCheck(DateTime.now());

      if (mounted) {
        // 5. Verificar si debe mostrar esta actualización
        final shouldShowUpdate = updateInfo.hasUpdate &&
            await UpdatePreferencesService.shouldShowUpdate(updateInfo.latestVersion);

        // 6. Aplicar filtros adicionales
        final shouldShow = shouldShowUpdate &&
            (!widget.showOnlyForceUpdates || updateInfo.isForceUpdate);

        if (shouldShow && !updateInfo.hasError) {
          _showUpdateDialog(updateInfo);
        } else if (updateInfo.hasError) {
          print('⚠️ [AUTO_UPDATE] Error en verificación automática: ${updateInfo.error}');
        } else if (!shouldShowUpdate) {
          print('⚠️ [AUTO_UPDATE] Actualización omitida por el usuario');
        } else {
          print('✅ [AUTO_UPDATE] No hay actualizaciones disponibles');
        }
      }
    } catch (e) {
      print('❌ [AUTO_UPDATE] Error en verificación automática: $e');
    }
  }

  /// Mostrar diálogo de actualización automática
  void _showUpdateDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              updateInfo.isForceUpdate ? Icons.warning : Icons.system_update,
              color: updateInfo.isForceUpdate ? Colors.orange : Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                updateInfo.isForceUpdate 
                    ? 'Actualización Requerida' 
                    : 'Nueva Versión Disponible',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensaje principal
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
              
              // Changelog compacto
              if (updateInfo.changelog.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Novedades principales:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    _getCompactChangelog(updateInfo.changelog),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
              
              // Mensaje para actualizaciones forzadas
              if (updateInfo.isForceUpdate) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Esta actualización es obligatoria para continuar usando la aplicación.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Botón "Omitir esta versión" solo si no es forzada
          if (!updateInfo.isForceUpdate)
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await UpdatePreferencesService.setSkippedVersion(updateInfo.latestVersion);
                navigator.pop();
              },
              child: const Text('Omitir esta versión'),
            ),

          // Botón "Recordar más tarde" solo si no es forzada
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtener changelog compacto (primeras 3 líneas)
  String _getCompactChangelog(String changelog) {
    final lines = changelog.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length <= 3) {
      return changelog;
    }
    
    final compactLines = lines.take(3).toList();
    compactLines.add('• Y más mejoras...');
    return compactLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Configuración para la verificación automática
class AutoUpdateConfig {
  final bool enabled;
  final Duration delayBeforeCheck;
  final bool showOnlyForceUpdates;
  final bool checkOnlyOnce;

  const AutoUpdateConfig({
    this.enabled = true,
    this.delayBeforeCheck = const Duration(seconds: 3),
    this.showOnlyForceUpdates = false,
    this.checkOnlyOnce = true,
  });

  /// Configuración para desarrollo (más frecuente)
  static const AutoUpdateConfig development = AutoUpdateConfig(
    enabled: true,
    delayBeforeCheck: Duration(seconds: 2),
    showOnlyForceUpdates: false,
    checkOnlyOnce: false,
  );

  /// Configuración para producción (solo actualizaciones críticas)
  static const AutoUpdateConfig production = AutoUpdateConfig(
    enabled: true,
    delayBeforeCheck: Duration(seconds: 5),
    showOnlyForceUpdates: true,
    checkOnlyOnce: true,
  );

  /// Configuración deshabilitada
  static const AutoUpdateConfig disabled = AutoUpdateConfig(
    enabled: false,
  );
}

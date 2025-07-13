import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/metrics_service.dart';
import '../theme/app_theme.dart';
import 'accessibility_widgets.dart';

/// Widget que muestra un dashboard con métricas de la aplicación
class MetricsDashboard extends StatelessWidget {
  final bool showDetailedMetrics;
  final bool showSessionInfo;
  final bool showProductivityMetrics;

  const MetricsDashboard({
    super.key,
    this.showDetailedMetrics = true,
    this.showSessionInfo = true,
    this.showProductivityMetrics = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MetricsService>(
      builder: (context, metricsService, child) {
        final metrics = metricsService.getDashboardMetrics();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSessionInfo) ...[
              _buildSessionInfoCard(context, metrics['session_info']),
              const SizedBox(height: 16),
            ],
            
            if (showProductivityMetrics) ...[
              _buildProductivityCard(context, metrics['productivity']),
              const SizedBox(height: 16),
            ],
            
            if (showDetailedMetrics) ...[
              _buildTotalsCard(context, metrics['totals']),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSessionInfoCard(BuildContext context, Map<String, dynamic> sessionInfo) {
    return AccessibleCard(
      semanticLabel: 'Información de sesión actual',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Sesión Actual',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Duración',
                  sessionInfo['duration'] ?? '0m',
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Conteos',
                  '${sessionInfo['conteos'] ?? 0}',
                  Icons.inventory,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Errores',
                  '${sessionInfo['errors'] ?? 0}',
                  Icons.error_outline,
                  color: sessionInfo['errors'] > 0 
                      ? AppTheme.getErrorColor(Theme.of(context).brightness == Brightness.dark)
                      : null,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Pantallas',
                  '${sessionInfo['screens'] ?? 0}',
                  Icons.screen_search_desktop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityCard(BuildContext context, Map<String, dynamic> productivity) {
    return AccessibleCard(
      semanticLabel: 'Métricas de productividad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Productividad',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Conteos/Hora',
                  productivity['conteos_per_hour'] ?? '0',
                  Icons.speed,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Tasa de Error',
                  productivity['error_rate'] ?? '0%',
                  Icons.error_outline,
                  color: _getErrorRateColor(context, productivity['error_rate']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, Map<String, dynamic> totals) {
    return AccessibleCard(
      semanticLabel: 'Estadísticas totales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas Totales',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Sesiones',
                  '${totals['total_sessions'] ?? 0}',
                  Icons.login,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  context,
                  'Total Conteos',
                  '${totals['total_conteos'] ?? 0}',
                  Icons.inventory_2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Center(
            child: _buildMetricItem(
              context,
              'Días de Uso',
              '${totals['days_since_first_use'] ?? 0}',
              Icons.calendar_today,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: effectiveColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: effectiveColor.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color? _getErrorRateColor(BuildContext context, String? errorRate) {
    if (errorRate == null) return null;
    
    final rate = double.tryParse(errorRate.replaceAll('%', '')) ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (rate == 0) {
      return AppTheme.getSuccessColor(isDark);
    } else if (rate < 5) {
      return AppTheme.getWarningColor(isDark);
    } else {
      return AppTheme.getErrorColor(isDark);
    }
  }
}

/// Widget compacto para mostrar métricas en la barra de la app
class CompactMetricsWidget extends StatelessWidget {
  const CompactMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MetricsService>(
      builder: (context, metricsService, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactMetric(
              context,
              '${metricsService.currentSessionConteos}',
              Icons.inventory,
              'Conteos de esta sesión',
            ),
            const SizedBox(width: 16),
            _buildCompactMetric(
              context,
              '${metricsService.currentSessionDuration.inMinutes}m',
              Icons.timer,
              'Duración de la sesión',
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactMetric(
    BuildContext context,
    String value,
    IconData icon,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
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

/// Widget para mostrar métricas en tiempo real
class LiveMetricsWidget extends StatefulWidget {
  const LiveMetricsWidget({super.key});

  @override
  State<LiveMetricsWidget> createState() => _LiveMetricsWidgetState();
}

class _LiveMetricsWidgetState extends State<LiveMetricsWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MetricsService>(
      builder: (context, metricsService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Métricas en Tiempo Real',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                LinearProgressIndicator(
                  value: metricsService.currentSessionConteos / 10, // Ejemplo: meta de 10 conteos
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Progreso de conteos: ${metricsService.currentSessionConteos}/10',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLiveMetric(
                      context,
                      'Tiempo',
                      '${metricsService.currentSessionDuration.inMinutes}m',
                      Icons.access_time,
                    ),
                    _buildLiveMetric(
                      context,
                      'Conteos',
                      '${metricsService.currentSessionConteos}',
                      Icons.inventory,
                    ),
                    _buildLiveMetric(
                      context,
                      'Errores',
                      '${metricsService.currentSessionErrors}',
                      Icons.error_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/widgets/theme_selector.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: AppBar(
            title: const Text('ReCount Pro'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () => _showLanguageSelector(context),
                tooltip: 'Cambiar idioma',
              ),
              IconButton(
                icon: const Icon(Icons.palette),
                onPressed: () => _showThemeSelector(context),
                tooltip: 'Cambiar tema',
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Título de bienvenida con degradado
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.subtleGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gradientStart.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¡Bienvenido a ReCount Pro!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.gradientStart,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistema profesional de conteo de inventarios',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gradientEnd,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Botones de navegación principales
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determinar número de columnas basado en el ancho de pantalla
                  int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  double childAspectRatio = constraints.maxWidth > 600 ? 0.9 : 0.95;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                    children: [
                  _buildNavigationCard(
                    context,
                    icon: Icons.person,
                    title: 'Perfil',
                    subtitle: 'Ver información personal',
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                  _buildNavigationCard(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Segundo Conteo',
                    subtitle: 'Conteo diario de VH',
                    gradient: AppTheme.primaryGradient,
                    onTap: () => Navigator.pushNamed(context, '/segundo-conteo'),
                  ),
                  _buildNavigationCard(
                    context,
                    icon: Icons.picture_as_pdf,
                    title: 'Reportes PDF',
                    subtitle: 'Generar reportes',
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/pdf'),
                  ),
                  _buildNavigationCard(
                    context,
                    icon: Icons.data_usage,
                    title: 'Gestión de Datos',
                    subtitle: 'Usuarios, VH y SKUs',
                    gradient: const LinearGradient(
                      colors: [AppTheme.gradientEnd, AppTheme.secondaryVariant],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/data-management'),
                  ),
                  _buildNavigationCard(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: 'Administración',
                    subtitle: 'Herramientas admin',
                    gradient: const LinearGradient(
                      colors: [AppTheme.gradientStart, AppTheme.primaryVariant],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/admin'),
                  ),
                  _buildNavigationCard(
                    context,
                    icon: Icons.settings,
                    title: 'Configuración',
                    subtitle: 'Ajustes del sistema',
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade500, Colors.grey.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determinar si es móvil basado en el ancho de pantalla
              bool isMobile = MediaQuery.of(context).size.width < 600;

              // Ajustar padding y tamaños basado en el espacio disponible
              double padding = constraints.maxWidth < 150 ? 10.0 : 16.0;
              double iconSize = constraints.maxWidth < 150 ? 24 : 32;
              double titleFontSize = constraints.maxWidth < 150 ? 11 : 14;
              double subtitleFontSize = constraints.maxWidth < 150 ? 9 : 12;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: iconSize,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight < 120 ? 6 : 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: titleFontSize,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: constraints.maxHeight < 120 ? 2 : 4),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: subtitleFontSize,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: isMobile ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const LanguageSelector(),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ThemeSelector(),
    );
  }


}

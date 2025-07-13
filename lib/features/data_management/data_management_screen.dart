import 'package:flutter/material.dart';
import 'user_management_screen.dart';
import 'vehicle_management_screen.dart';
import 'product_management_screen.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Datos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título y descripción
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.data_usage,
                      size: 48,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gestión Manual de Datos',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agregar, editar y gestionar usuarios, vehículos y productos manualmente',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Opciones de gestión
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildManagementCard(
                    context,
                    icon: Icons.people,
                    title: 'Usuarios',
                    subtitle: 'Gestionar verificadores',
                    color: Colors.blue,
                    onTap: () => _showUserManagement(context),
                  ),
                  _buildManagementCard(
                    context,
                    icon: Icons.local_shipping,
                    title: 'Vehículos (VH)',
                    subtitle: 'Gestionar flota y VH programados',
                    color: Colors.green,
                    onTap: () => _showVehicleManagement(context),
                  ),
                  _buildManagementCard(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Productos (SKU)',
                    subtitle: 'Gestionar catálogo de productos',
                    color: Colors.orange,
                    onTap: () => _showProductManagement(context),
                  ),
                  _buildManagementCard(
                    context,
                    icon: Icons.view_list,
                    title: 'Ver Datos',
                    subtitle: 'Consultar información existente',
                    color: Colors.purple,
                    onTap: () => _showDataViewer(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Información adicional
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Información',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Los datos se guardan automáticamente en Firebase\n'
                      '• Puedes agregar datos manualmente o importar desde Excel\n'
                      '• Los cambios se sincronizan en tiempo real',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserManagementScreen(),
      ),
    );
  }

  void _showVehicleManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VehicleManagementScreen(),
      ),
    );
  }

  void _showProductManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductManagementScreen(),
      ),
    );
  }

  void _showDataViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Visualizador de Datos'),
        content: const Text(
          'Funcionalidad en desarrollo.\n\n'
          'Aquí podrás:\n'
          '• Ver todos los datos existentes\n'
          '• Buscar y filtrar información\n'
          '• Exportar datos a Excel',
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
}

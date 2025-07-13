import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  // Estadísticas simuladas
  int _vhContados = 0;
  int _vhProgramados = 0;
  int _totalUsuarios = 0;
  int _totalVehiculos = 0;
  int _totalProductos = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📊 [PROFILE] Cargando estadísticas reales de Firebase...');
      final firestore = FirebaseFirestore.instance;

      // Obtener estadísticas en paralelo para mejor rendimiento
      final futures = await Future.wait([
        _obtenerTotalUsuarios(firestore),
        _obtenerTotalVehiculos(firestore),
        _obtenerTotalProductos(firestore),
        _obtenerTotalConteos(firestore),
      ]);

      setState(() {
        _totalUsuarios = futures[0] as int;
        _totalVehiculos = futures[1] as int;
        _totalProductos = futures[2] as int;
        final conteosData = futures[3] as Map<String, int>;
        _vhContados = conteosData['contados'] ?? 0;
        _vhProgramados = conteosData['programados'] ?? 0;
        _isLoading = false;
      });

      print('✅ [PROFILE] Estadísticas cargadas: Usuarios=$_totalUsuarios, Vehículos=$_totalVehiculos, Productos=$_totalProductos, Contados=$_vhContados, Programados=$_vhProgramados');
    } catch (e) {
      print('❌ [PROFILE] Error cargando estadísticas: $e');
      // Usar datos de respaldo en caso de error
      setState(() {
        _totalUsuarios = 0;
        _totalVehiculos = 0;
        _totalProductos = 0;
        _vhContados = 0;
        _vhProgramados = 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEstadisticas,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (mounted) {
                navigator.pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          final userModel = authService.userModel;

          if (userModel == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: Usuario no autenticado'),
                ],
              ),
            );
          }

          return _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: _cargarEstadisticas,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjeta de perfil
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: _getRoleColor(userModel.rol),
                                  child: Text(
                                    userModel.nombre[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userModel.nombre,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        userModel.email,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(userModel.rol),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getRoleDisplayName(userModel.rol),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Indicador de estado
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: userModel.activo ? Colors.green.shade100 : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    userModel.activo ? Icons.check_circle : Icons.cancel,
                                    color: userModel.activo ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                    // Estadísticas de la aplicación
                    const Text(
                      'Estadísticas de la Aplicación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Usuarios',
                            _totalUsuarios.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Vehículos',
                            _totalVehiculos.toString(),
                            Icons.local_shipping,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Productos',
                            _totalProductos.toString(),
                            Icons.inventory_2,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Conteos',
                            (_vhContados + _vhProgramados).toString(),
                            Icons.check_circle,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Productividad Diaria
                    const Text(
                      'Productividad de Hoy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Métricas de productividad diaria
                    Row(
                      children: [
                        Expanded(
                          child: _buildProductivityCard(
                            'VH Programados',
                            _vhProgramados.toString(),
                            Icons.schedule,
                            Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProductivityCard(
                            'VH Contados',
                            _vhContados.toString(),
                            Icons.check_circle_outline,
                            Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Porcentaje de conteo
                    _buildProgressCard(
                      'Progreso de Conteo',
                      _vhProgramados > 0 ? (_vhContados / _vhProgramados * 100) : 0,
                      _vhContados,
                      _vhProgramados,
                    ),
                    const SizedBox(height: 30),

                    // Botones de acción
                    const Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/segundo-conteo');
                        },
                        icon: const Icon(Icons.add_task),
                        label: const Text(
                          'Iniciar Segundo Conteo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/pdf');
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text(
                          'Generar Reportes PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/data-management');
                        },
                        icon: const Icon(Icons.data_usage),
                        label: const Text(
                          'Gestión de Datos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal,
                          side: const BorderSide(color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin');
                        },
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text(
                          'Administración',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: const BorderSide(color: Colors.indigo),
                        ),
                      ),
                    ),
                        ],
                      ),
                    ),
                  );
        },
      ),
    );
  }

  Color _getRoleColor(String rol) {
    switch (rol) {
      case 'admin':
        return Colors.red;
      case 'supervisor':
        return Colors.orange;
      case 'editor':
        return Colors.green;
      case 'verificador':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String rol) {
    switch (rol) {
      case 'admin':
        return 'ADMINISTRADOR';
      case 'supervisor':
        return 'SUPERVISOR';
      case 'editor':
        return 'EDITOR';
      case 'verificador':
        return 'VERIFICADOR';
      case 'viewer':
        return 'VISUALIZADOR';
      default:
        return rol.toUpperCase();
    }
  }

  /// Obtener total de usuarios registrados
  Future<int> _obtenerTotalUsuarios(FirebaseFirestore firestore) async {
    try {
      print('👥 [PROFILE] Obteniendo total de usuarios...');

      // Intentar con la colección 'users' primero
      var snapshot = await firestore.collection('users').get();
      if (snapshot.docs.isNotEmpty) {
        print('✅ [PROFILE] Encontrados ${snapshot.docs.length} usuarios en colección "users"');
        return snapshot.docs.length;
      }

      // Si no hay usuarios en 'users', intentar con 'verificadores'
      snapshot = await firestore.collection('verificadores').get();
      print('✅ [PROFILE] Encontrados ${snapshot.docs.length} usuarios en colección "verificadores"');
      return snapshot.docs.length;
    } catch (e) {
      print('❌ [PROFILE] Error obteniendo usuarios: $e');
      return 0;
    }
  }

  /// Obtener total de vehículos
  Future<int> _obtenerTotalVehiculos(FirebaseFirestore firestore) async {
    try {
      print('🚛 [PROFILE] Obteniendo total de vehículos...');

      // Intentar con 'vh_programados' primero
      var snapshot = await firestore.collection('vh_programados').get();
      if (snapshot.docs.isNotEmpty) {
        // Contar placas únicas para evitar duplicados
        final placasUnicas = <String>{};
        for (var doc in snapshot.docs) {
          final placa = doc.data()['placa'] as String?;
          if (placa != null && placa.isNotEmpty) {
            placasUnicas.add(placa);
          }
        }
        print('✅ [PROFILE] Encontrados ${placasUnicas.length} vehículos únicos en "vh_programados"');
        return placasUnicas.length;
      }

      // Si no hay datos, intentar con 'flota'
      snapshot = await firestore.collection('flota').get();
      print('✅ [PROFILE] Encontrados ${snapshot.docs.length} vehículos en colección "flota"');
      return snapshot.docs.length;
    } catch (e) {
      print('❌ [PROFILE] Error obteniendo vehículos: $e');
      return 0;
    }
  }

  /// Obtener total de productos/SKUs
  Future<int> _obtenerTotalProductos(FirebaseFirestore firestore) async {
    try {
      print('📦 [PROFILE] Obteniendo total de productos...');

      // La colección en Firebase se llama 'sku' (singular), no 'skus'
      final snapshot = await firestore.collection('sku').get();
      print('✅ [PROFILE] Encontrados ${snapshot.docs.length} productos en colección "sku"');
      return snapshot.docs.length;
    } catch (e) {
      print('❌ [PROFILE] Error obteniendo productos: $e');
      return 0;
    }
  }

  /// Obtener estadísticas de conteos
  Future<Map<String, int>> _obtenerTotalConteos(FirebaseFirestore firestore) async {
    try {
      print('✅ [PROFILE] Obteniendo estadísticas de conteos...');

      // Obtener conteos realizados
      final conteosSnapshot = await firestore.collection('conteos').get();
      final segundosConteosSnapshot = await firestore.collection('segundo_conteos').get();

      // Obtener VH programados para hoy
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final vhProgramadosSnapshot = await firestore
          .collection('vh_programados')
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .get();

      final totalContados = conteosSnapshot.docs.length + segundosConteosSnapshot.docs.length;
      final totalProgramados = vhProgramadosSnapshot.docs.length;

      print('✅ [PROFILE] Conteos: $totalContados realizados, $totalProgramados programados para hoy');

      return {
        'contados': totalContados,
        'programados': totalProgramados,
      };
    } catch (e) {
      print('❌ [PROFILE] Error obteniendo conteos: $e');
      return {'contados': 0, 'programados': 0};
    }
  }

  Widget _buildProductivityCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    String title,
    double percentage,
    int completed,
    int total,
  ) {
    final progressColor = percentage >= 100
        ? Colors.green
        : percentage >= 75
            ? Colors.blue
            : percentage >= 50
                ? Colors.orange
                : Colors.red;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed de $total VH',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  total > 0 ? '${total - completed} restantes' : 'Sin datos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
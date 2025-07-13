import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _conductorController = TextEditingController();
  final TextEditingController _rutaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedEstado = 'programado';

  final List<String> _estados = [
    'programado',
    'en_ruta',
    'completado',
    'cancelado',
  ];

  @override
  void dispose() {
    _placaController.dispose();
    _conductorController.dispose();
    _rutaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Vehículos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVehicleDialog(),
            tooltip: 'Agregar vehículo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por placa, conductor o ruta...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Lista de vehículos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('vh_programados').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Filtrar por búsqueda
                final filteredDocs = docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  
                  final data = doc.data() as Map<String, dynamic>;
                  final placa = (data['placa'] ?? '').toString().toLowerCase();
                  final conductor = (data['conductor'] ?? '').toString().toLowerCase();
                  final ruta = (data['ruta'] ?? '').toString().toLowerCase();
                  
                  return placa.contains(_searchQuery) || 
                         conductor.contains(_searchQuery) || 
                         ruta.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No hay vehículos registrados'
                              : 'No se encontraron vehículos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca el botón + para agregar un vehículo',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(data['estado']),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          data['placa'] ?? 'Sin placa',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['conductor'] != null)
                              Text('Conductor: ${data['conductor']}'),
                            if (data['ruta'] != null)
                              Text('Ruta: ${data['ruta']}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(data['estado']),
                                  size: 16,
                                  color: _getStatusColor(data['estado']),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusText(data['estado']),
                                  style: TextStyle(
                                    color: _getStatusColor(data['estado']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditVehicleDialog(doc.id, data);
                                break;
                              case 'delete':
                                _showDeleteConfirmation(doc.id, data['placa']);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? estado) {
    switch (estado) {
      case 'programado':
        return Colors.blue;
      case 'en_ruta':
        return Colors.orange;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? estado) {
    switch (estado) {
      case 'programado':
        return Icons.schedule;
      case 'en_ruta':
        return Icons.directions_car;
      case 'completado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String? estado) {
    switch (estado) {
      case 'programado':
        return 'Programado';
      case 'en_ruta':
        return 'En Ruta';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  void _showAddVehicleDialog() {
    _placaController.clear();
    _conductorController.clear();
    _rutaController.clear();
    _selectedEstado = 'programado';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Vehículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _placaController,
                decoration: const InputDecoration(
                  labelText: 'Placa *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _conductorController,
                decoration: const InputDecoration(
                  labelText: 'Conductor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rutaController,
                decoration: const InputDecoration(
                  labelText: 'Ruta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: _estados.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(_getStatusText(estado)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEstado = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _addVehicle,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditVehicleDialog(String docId, Map<String, dynamic> vehicleData) {
    _placaController.text = vehicleData['placa'] ?? '';
    _conductorController.text = vehicleData['conductor'] ?? '';
    _rutaController.text = vehicleData['ruta'] ?? '';
    _selectedEstado = vehicleData['estado'] ?? 'programado';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Vehículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _placaController,
                decoration: const InputDecoration(
                  labelText: 'Placa *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _conductorController,
                decoration: const InputDecoration(
                  labelText: 'Conductor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rutaController,
                decoration: const InputDecoration(
                  labelText: 'Ruta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: _estados.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(_getStatusText(estado)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEstado = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _updateVehicle(docId),
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addVehicle() async {
    if (_placaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La placa es obligatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('vh_programados').add({
        'placa': _placaController.text.trim().toUpperCase(),
        'conductor': _conductorController.text.trim().isNotEmpty 
            ? _conductorController.text.trim() 
            : null,
        'ruta': _rutaController.text.trim().isNotEmpty 
            ? _rutaController.text.trim() 
            : null,
        'estado': _selectedEstado,
        'fecha': DateTime.now().toIso8601String(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        '_metadata': {
          'source': 'manual_entry',
          'created_by': 'admin',
          'version': '1.0',
        },
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar vehículo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateVehicle(String docId) async {
    if (_placaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La placa es obligatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('vh_programados').doc(docId).update({
        'placa': _placaController.text.trim().toUpperCase(),
        'conductor': _conductorController.text.trim().isNotEmpty 
            ? _conductorController.text.trim() 
            : null,
        'ruta': _rutaController.text.trim().isNotEmpty 
            ? _rutaController.text.trim() 
            : null,
        'estado': _selectedEstado,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar vehículo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation(String docId, String placa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el vehículo "$placa"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVehicle(docId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(String docId) async {
    try {
      await _firestore.collection('vh_programados').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo eliminado exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar vehículo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

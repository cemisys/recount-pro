import 'package:flutter/material.dart';
import '../../services/excel_to_sqlite_service.dart';
// import '../../core/services/logger_service.dart';

class ExcelToFirebaseScreen extends StatefulWidget {
  const ExcelToFirebaseScreen({super.key});

  @override
  State<ExcelToFirebaseScreen> createState() => _ExcelToFirebaseScreenState();
}

class _ExcelToFirebaseScreenState extends State<ExcelToFirebaseScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, int> _collectionCounts = {};
  Map<String, dynamic> _importStats = {};

  @override
  void initState() {
    super.initState();
    _loadCollectionCounts();
  }

  Future<void> _loadCollectionCounts() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Cargando estadísticas de Firebase...';
    });

    try {
      final stats = await ExcelToFirebaseService.getImportStats();

      setState(() {
        _collectionCounts = Map<String, int>.from(stats['collection_counts'] ?? {});
        _importStats = stats;
        _statusMessage = 'Estadísticas actualizadas';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error cargando estadísticas: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importFromExcel() async {
    // Mostrar confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar desde Excel'),
        content: const Text(
          '¿Estás seguro de que quieres importar los datos del archivo Excel a Firebase?\n\n'
          'Esta operación agregará los datos del Excel a Firebase conservando los nombres originales de las hojas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Importando datos desde Excel a Firebase...';
    });

    try {
      final success = await ExcelToFirebaseService.importExcelToFirebase();

      if (success) {
        setState(() {
          _statusMessage = '¡Datos importados exitosamente desde Excel a Firebase!';
        });

        // Actualizar estadísticas
        await _loadCollectionCounts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Datos importados exitosamente desde Excel a Firebase'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _statusMessage = 'Error importando datos desde Excel';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error importando datos desde Excel'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel a Firebase'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCollectionCounts,
            tooltip: 'Actualizar estadísticas',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado actual
            Card(
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
                          'Estado Actual',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      Text('Estado: $_statusMessage'),
                      const SizedBox(height: 8),
                      if (_importStats.isNotEmpty) ...[
                        Text('Total de registros: ${_importStats['total_records'] ?? 0}'),
                        if (_importStats['import_date'] != null)
                          Text('Última importación: ${_importStats['import_date']}'),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estadísticas de colecciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Estadísticas de Firebase',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_collectionCounts.isEmpty)
                      const Text('No hay datos importados en Firebase')
                    else
                      Column(
                        children: _collectionCounts.entries.map((entry) {
                          final collectionName = entry.key;
                          final count = entry.value;

                          return ListTile(
                            leading: Icon(
                              count > 0 ? Icons.check_circle : Icons.warning,
                              color: count > 0 ? Colors.green : Colors.orange,
                            ),
                            title: Text(collectionName),
                            subtitle: Text('$count documentos'),
                            trailing: count > 0
                                ? Chip(
                                    label: Text('$count'),
                                    backgroundColor: Colors.green.shade100,
                                  )
                                : null,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Acciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _importFromExcel,
                      icon: const Icon(Icons.download),
                      label: const Text('Importar desde Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadCollectionCounts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar Estadísticas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Información adicional
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      '• Los datos se importan desde el archivo Excel en assets/data\n'
                      '• La importación preserva los nombres originales de las hojas\n'
                      '• Cada hoja se convierte en una colección de Firebase\n'
                      '• Se agregan metadatos de importación a cada documento\n'
                      '• Los datos quedan disponibles en tiempo real en Firebase',
                      style: TextStyle(fontSize: 14),
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
}

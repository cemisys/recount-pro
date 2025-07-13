import 'package:flutter/material.dart';
import '../../tools/data_loader.dart';

class DataAdminScreen extends StatefulWidget {
  const DataAdminScreen({super.key});

  @override
  State<DataAdminScreen> createState() => _DataAdminScreenState();
}

class _DataAdminScreenState extends State<DataAdminScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, int> _collectionsStatus = {};

  @override
  void initState() {
    super.initState();
    _loadCollectionsStatus();
  }

  Future<void> _loadCollectionsStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Verificando estado de las colecciones...';
    });

    try {
      final status = await DataLoader.getCollectionsStatus();
      setState(() {
        _collectionsStatus = status;
        _statusMessage = 'Estado de colecciones actualizado';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error verificando colecciones: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDataFromExcel() async {
    // Mostrar confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Carga de Datos'),
        content: const Text(
          '¿Estás seguro de que quieres cargar los datos desde el archivo Excel?\n\n'
          'Esta operación puede tomar varios minutos y agregará nuevos documentos a Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Cargando datos desde Excel...';
    });

    try {
      await DataLoader.loadAllData();
      setState(() {
        _statusMessage = '¡Datos cargados exitosamente!';
      });
      
      // Actualizar estado de colecciones
      await _loadCollectionsStatus();
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos cargados exitosamente desde Excel'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error cargando datos: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCollectionDetails(String collectionName) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Detalles de $collectionName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: DataLoader.getCollectionDetails(collectionName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final details = snapshot.data!;
                    final sampleDocs = details['sample_documents'] as List;
                    final fields = details['fields'] as List;
                    final hasMetadata = details['has_metadata'] as bool;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información general
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Información General',
                                       style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Text('Total de documentos: ${details['count']}'),
                                  Text('Campos encontrados: ${fields.length}'),
                                  Text('Tiene metadatos de importación: ${hasMetadata ? "Sí" : "No"}'),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Campos
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Campos (${fields.length})',
                                       style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: fields.map<Widget>((field) =>
                                      Chip(label: Text(field.toString()))
                                    ).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Documentos de muestra
                          if (sampleDocs.isNotEmpty) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Documentos de Muestra (${sampleDocs.length})',
                                         style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    ...sampleDocs.map((doc) =>
                                      ExpansionTile(
                                        title: Text('ID: ${doc['id']}'),
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              doc['data'].toString(),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearCollection(String collectionName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpiar Colección: $collectionName'),
        content: Text(
          '¿Estás seguro de que quieres eliminar TODOS los documentos de la colección "$collectionName"?\n\n'
          '⚠️ Esta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Limpiando colección $collectionName...';
    });

    try {
      await DataLoader.clearCollection(collectionName);
      setState(() {
        _statusMessage = 'Colección $collectionName limpiada exitosamente';
      });
      
      await _loadCollectionsStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Colección $collectionName limpiada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error limpiando colección: $e';
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
        title: const Text('Administración de Datos'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
                    Text(
                      'Estado Actual',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botones de acción
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
                      onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/excel-preview'),
                      icon: const Icon(Icons.preview),
                      label: const Text('Vista Previa del Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/excel-to-firebase'),
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Excel a Firebase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadDataFromExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Cargar Datos desde Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadCollectionsStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar Estado'),
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
            
            // Estado de colecciones
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de Colecciones',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      if (_collectionsStatus.isEmpty)
                        const Text('No hay información de colecciones disponible')
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _collectionsStatus.length,
                            itemBuilder: (context, index) {
                              final entry = _collectionsStatus.entries.elementAt(index);
                              final collectionName = entry.key;
                              final documentCount = entry.value;
                              
                              return ListTile(
                                leading: Icon(
                                  documentCount > 0 ? Icons.check_circle : Icons.warning,
                                  color: documentCount > 0 ? Colors.green : Colors.orange,
                                ),
                                title: Text(collectionName),
                                subtitle: Text('$documentCount documentos'),
                                trailing: documentCount > 0
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.info, color: Colors.blue),
                                            onPressed: _isLoading
                                                ? null
                                                : () => _showCollectionDetails(collectionName),
                                            tooltip: 'Ver detalles',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: _isLoading
                                                ? null
                                                : () => _clearCollection(collectionName),
                                            tooltip: 'Limpiar colección',
                                          ),
                                        ],
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

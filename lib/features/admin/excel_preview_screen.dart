import 'package:flutter/material.dart';
import '../../tools/excel_analyzer.dart';

class ExcelPreviewScreen extends StatefulWidget {
  const ExcelPreviewScreen({super.key});

  @override
  State<ExcelPreviewScreen> createState() => _ExcelPreviewScreenState();
}

class _ExcelPreviewScreenState extends State<ExcelPreviewScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _analysisData;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _analyzeExcelFile();
  }

  Future<void> _analyzeExcelFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Analizando archivo Excel...';
    });

    try {
      final analysis = await ExcelAnalyzer.analyzeExcelFile();
      setState(() {
        _analysisData = analysis;
        _statusMessage = 'Análisis completado exitosamente';
      });
      
      // Imprimir reporte detallado en consola
      ExcelAnalyzer.printDetailedReport(analysis);
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error analizando archivo: $e';
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
        title: const Text('Vista Previa del Excel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _analyzeExcelFile,
            tooltip: 'Reanalizar archivo',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analizando archivo Excel...'),
                ],
              ),
            )
          : _analysisData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_statusMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _analyzeExcelFile,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildAnalysisView(),
    );
  }

  Widget _buildAnalysisView() {
    final analysis = _analysisData!;
    final summary = analysis['summary'] as Map<String, dynamic>;
    final sheets = analysis['sheets'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información general
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Información General',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Archivo', analysis['fileName']),
                  _buildInfoRow('Total de hojas', '${analysis['totalSheets']}'),
                  _buildInfoRow('Total de filas con datos', '${summary['totalDataRows']}'),
                  _buildInfoRow('Headers únicos', '${summary['uniqueHeaders']}'),
                  if (summary['totalEmptyRows'] > 0)
                    _buildInfoRow('Filas vacías', '${summary['totalEmptyRows']}', Colors.orange),
                  if (summary['totalDuplicateRows'] > 0)
                    _buildInfoRow('Filas duplicadas', '${summary['totalDuplicateRows']}', Colors.red),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de hojas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Hojas del Excel',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...sheets.entries.map((entry) => _buildSheetCard(entry.key, entry.value)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botón para proceder con la carga
          if (_analysisData != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLoadConfirmation(),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Proceder con la Carga a Firebase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetCard(String sheetName, Map<String, dynamic> sheetData) {
    final bool exists = sheetData['exists'] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ExpansionTile(
        leading: Icon(
          exists ? Icons.check_circle : Icons.error,
          color: exists ? Colors.green : Colors.red,
        ),
        title: Text(sheetName),
        subtitle: exists 
            ? Text('${sheetData['dataRows']} filas • ${sheetData['totalColumns']} columnas')
            : Text('Error: ${sheetData['error']}'),
        children: exists ? [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Headers:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (sheetData['headers'] as List<String>)
                      .map((header) => Chip(
                            label: Text(header),
                            backgroundColor: Colors.blue.shade50,
                          ))
                      .toList(),
                ),
                
                if (sheetData['sampleData'] != null && 
                    (sheetData['sampleData'] as List).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Muestra de datos:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (sheetData['sampleData'] as List<Map<String, dynamic>>)
                          .take(2)
                          .map((sample) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  sample.toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] : [],
      ),
    );
  }

  void _showLoadConfirmation() {
    final summary = _analysisData!['summary'] as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Carga de Datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se cargarán los siguientes datos a Firebase:'),
            const SizedBox(height: 16),
            Text('• Total de filas: ${summary['totalDataRows']}'),
            Text('• Hojas: ${_analysisData!['totalSheets']}'),
            Text('• Headers únicos: ${summary['uniqueHeaders']}'),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Esta operación puede tomar varios minutos.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/admin');
            },
            child: const Text('Proceder con la Carga'),
          ),
        ],
      ),
    );
  }
}

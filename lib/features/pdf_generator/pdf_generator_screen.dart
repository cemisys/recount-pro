import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/vh_model.dart';
import 'pdf_service.dart';

class PdfGeneratorScreen extends StatefulWidget {
  const PdfGeneratorScreen({super.key});

  @override
  State<PdfGeneratorScreen> createState() => _PdfGeneratorScreenState();
}

class _PdfGeneratorScreenState extends State<PdfGeneratorScreen> {
  List<ConteoVh> _conteosDelDia = [];
  List<VhSegundoConteo> _segundosConteosDelDia = [];
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarConteos();
  }

  Future<void> _cargarConteos() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    if (authService.user != null) {
      print('🔍 [PDF] Cargando conteos para usuario: ${authService.user!.uid}');

      // Cargar conteos normales
      final conteos = await firebaseService.getConteosHoy(authService.user!.uid);
      print('📊 [PDF] Conteos normales cargados: ${conteos.length}');

      // Cargar segundos conteos
      final segundosConteos = await firebaseService.getSegundosConteosHoy(authService.user!.uid);
      print('📊 [PDF] Segundos conteos cargados: ${segundosConteos.length}');

      for (var conteo in segundosConteos) {
        print('  - ${conteo.placa} (${conteo.tieneNovedad ? "con novedad" : "sin novedad"})');
      }

      setState(() {
        _conteosDelDia = conteos;
        _segundosConteosDelDia = segundosConteos;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generarPDF() async {
    if (_conteosDelDia.isEmpty && _segundosConteosDelDia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay conteos disponibles para generar el reporte.\n'
                      'Primer conteo: ${_conteosDelDia.length} VH\n'
                      'Segundo conteo: ${_segundosConteosDelDia.length} VH'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final pdfService = PdfService();
      
      final success = await pdfService.generarReporteDiario(
        conteos: _conteosDelDia,
        segundosConteos: _segundosConteosDelDia,
        verificador: authService.userModel!,
        fecha: _fechaSeleccionada,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generado y compartido exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al generar el PDF'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
      await _cargarConteos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarConteos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del reporte
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información del Reporte',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              const Icon(Icons.person, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Verificador: ${authService.userModel?.nombre ?? "N/A"}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 16),
                              TextButton(
                                onPressed: _seleccionarFecha,
                                child: const Text('Cambiar fecha'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Debug info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estado de Carga:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Primer conteo: ${_conteosDelDia.length} VH'),
                                Text('Segundo conteo: ${_segundosConteosDelDia.length} VH'),
                                Text('Total: ${_conteosDelDia.length + _segundosConteosDelDia.length} VH'),
                                Text('Cargando: ${_isLoading ? "Sí" : "No"}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(Icons.assignment, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Total VH contados: ${_conteosDelDia.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              const Icon(Icons.warning, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'VH con novedades: ${_conteosDelDia.where((c) => c.tieneNovedad).length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _conteosDelDia.where((c) => c.tieneNovedad).isNotEmpty
                                      ? AppTheme.errorColor
                                      : AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información de segundos conteos
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
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Segundo Conteo',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gradientStart,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 20, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Total VH contados: ${_segundosConteosDelDia.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(Icons.warning, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'VH con novedades: ${_segundosConteosDelDia.where((c) => c.tieneNovedad).length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _segundosConteosDelDia.where((c) => c.tieneNovedad).isNotEmpty
                                      ? AppTheme.errorColor
                                      : AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Lista de conteos
                  const Text(
                    'Conteos del Día',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_conteosDelDia.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay conteos registrados para esta fecha',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _conteosDelDia.length,
                      itemBuilder: (context, index) {
                        final conteo = _conteosDelDia[index];
                        return Card(
                          child: ExpansionTile(
                            leading: Icon(
                              conteo.tieneNovedad 
                                  ? Icons.warning 
                                  : Icons.check_circle,
                              color: conteo.tieneNovedad 
                                  ? AppTheme.errorColor 
                                  : AppTheme.successColor,
                            ),
                            title: Text(
                              'VH: ${conteo.vhId} - ${conteo.placa}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Hora: ${DateFormat('HH:mm').format(conteo.fechaCreacion)}',
                            ),
                            children: [
                              if (conteo.tieneNovedad && conteo.novedades != null)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Novedades:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...conteo.novedades!.map((novedad) => 
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${novedad.tipo}: ${novedad.sku}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text('Descripción: ${novedad.descripcion}'),
                                                Text('DT: ${novedad.dt}'),
                                                Text('Diferencia: ${novedad.diferencia}'),
                                                Text('Armador: ${novedad.armador}'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Lista de segundos conteos
                  if (_segundosConteosDelDia.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Segundos Conteos del Día',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _segundosConteosDelDia.length,
                      itemBuilder: (context, index) {
                        final conteo = _segundosConteosDelDia[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                conteo.placa.substring(0, 2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              conteo.placa,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verificador: ${conteo.verificadorNombre}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Hora: ${DateFormat('HH:mm').format(conteo.timestamp)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (conteo.observaciones != null)
                                  Text(
                                    'Observaciones: ${conteo.observaciones}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: conteo.tieneNovedad ? Colors.orange[100] : Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conteo.tieneNovedad
                                    ? '${conteo.novedades.length} novedad(es)'
                                    : 'Sin novedades',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: conteo.tieneNovedad ? Colors.orange[800] : Colors.green[800],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Botón generar PDF - SIEMPRE VISIBLE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingPdf ? null : _generarPDF,
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(
                        _isGeneratingPdf
                            ? 'Generando PDF...'
                            : 'Generar y Compartir PDF',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nota
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El PDF incluirá todos los conteos (primer y segundo conteo) del día seleccionado con sus respectivas novedades.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/vh_model.dart';
import '../../core/services/validation_service.dart';
import '../../core/services/metrics_service.dart';

class SegundoConteoScreenNew extends StatefulWidget {
  const SegundoConteoScreenNew({super.key});

  @override
  State<SegundoConteoScreenNew> createState() => _SegundoConteoScreenNewState();
}

class _SegundoConteoScreenNewState extends State<SegundoConteoScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _vhProgramadosController = TextEditingController();
  final _vhSalenController = TextEditingController();

  // Variables para la sesión de segundo conteo
  final List<VhSegundoConteo> _vhContados = [];
  DateTime? _inicioSesion;

  // Variables para el VH actual
  bool _placaValidada = false;
  bool _tieneNovedad = false;
  String _tipoNovedad = 'Faltante';
  final _dtController = TextEditingController();
  final _skuController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _alistadoController = TextEditingController();
  final _fisicoController = TextEditingController();
  final _verificadoController = TextEditingController();
  final _armadorController = TextEditingController();

  final List<NovedadConteo> _novedadesActuales = [];
  int _diferencia = 0;

  // Variables para búsqueda incremental de placas
  List<String> _placasSugeridas = [];
  bool _mostrandoSugerencias = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _alistadoController.addListener(_calcularDiferenciaNovedad);
    _fisicoController.addListener(_calcularDiferenciaNovedad);

    // Inicializar tiempo de sesión para métricas
    _inicioSesion = DateTime.now();

    // Verificar datos de VH programados al inicializar
    _verificarDatosVhProgramados();
  }

  /// Función temporal para verificar si hay datos de VH programados
  Future<void> _verificarDatosVhProgramados() async {
    try {
      print('🔍 [SEGUNDO_CONTEO] Verificando datos de VH programados...');
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);

      // Hacer una búsqueda con una letra común para ver si hay datos
      final placasTest = await firebaseService.buscarPlacas('A');
      print('📊 [SEGUNDO_CONTEO] Test con "A": ${placasTest.length} placas encontradas');

      if (placasTest.isEmpty) {
        // Intentar con otra letra
        final placasTest2 = await firebaseService.buscarPlacas('B');
        print('📊 [SEGUNDO_CONTEO] Test con "B": ${placasTest2.length} placas encontradas');

        if (placasTest2.isEmpty) {
          print('⚠️ [SEGUNDO_CONTEO] ADVERTENCIA: No se encontraron VH programados para hoy');
          print('   Esto puede significar que:');
          print('   1. No hay datos en la colección vh_programados');
          print('   2. No hay VH programados para la fecha actual');
          print('   3. Hay un problema con la consulta de Firebase');

          // Crear algunos datos de prueba
          await _crearDatosDePrueba();
        }
      }

      // Probar búsquedas específicas para verificar que funciona
      await _probarBusquedas();
    } catch (e) {
      print('❌ [SEGUNDO_CONTEO] Error verificando datos: $e');
    }
  }

  /// Crear algunos VH de prueba para testing
  Future<void> _crearDatosDePrueba() async {
    try {
      print('🔧 [SEGUNDO_CONTEO] Creando datos de prueba...');

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Usar exactamente la misma lógica de fecha que usa la búsqueda
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12, 0, 0); // Mediodía de hoy

      final vhPrueba = [
        {'vh_id': 'VH001', 'placa': 'ABC123'},
        {'vh_id': 'VH002', 'placa': 'DEF456'},
        {'vh_id': 'VH003', 'placa': 'GHI789'},
        {'vh_id': 'VH004', 'placa': 'JKL012'},
        {'vh_id': 'VH005', 'placa': 'MNO345'},
        {'vh_id': 'VH006', 'placa': 'PQR678'},
        {'vh_id': 'VH007', 'placa': 'STU901'},
        {'vh_id': 'VH008', 'placa': 'VWX234'},
      ];

      for (final vh in vhPrueba) {
        final docRef = firestore.collection('vh_programados').doc();
        batch.set(docRef, {
          'vh_id': vh['vh_id'],
          'placa': vh['placa'],
          'fecha': today,
          'productos': [],
          'created_at': FieldValue.serverTimestamp(),
          '_metadata': {
            'source': 'test_data',
            'created_by': 'system',
            'version': '1.0',
          },
        });
      }

      await batch.commit();
      print('✅ [SEGUNDO_CONTEO] ${vhPrueba.length} VH de prueba creados exitosamente');

      // Mostrar mensaje al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se crearon ${vhPrueba.length} VH de prueba para testing'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      print('❌ [SEGUNDO_CONTEO] Error creando datos de prueba: $e');
    }
  }

  /// Probar búsquedas específicas para verificar funcionamiento
  Future<void> _probarBusquedas() async {
    try {
      print('🧪 [SEGUNDO_CONTEO] Probando búsquedas específicas...');
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);

      // Probar búsquedas con las placas que sabemos que existen
      final tests = ['A', 'AB', 'ABC', 'D', 'DE', 'DEF', 'G', 'GH', 'GHI'];

      for (final query in tests) {
        final resultados = await firebaseService.buscarPlacas(query);
        print('🔍 [TEST] "$query" -> ${resultados.length} resultados: ${resultados.join(', ')}');

        if (resultados.isNotEmpty) {
          print('✅ [TEST] Búsqueda funcionando correctamente con "$query"');
          break;
        }
      }
    } catch (e) {
      print('❌ [SEGUNDO_CONTEO] Error probando búsquedas: $e');
    }
  }

  @override
  void dispose() {
    _ocultarSugerencias();
    _placaController.dispose();
    _vhProgramadosController.dispose();
    _vhSalenController.dispose();
    _dtController.dispose();
    _skuController.dispose();
    _descripcionController.dispose();
    _alistadoController.dispose();
    _fisicoController.dispose();
    _verificadoController.dispose();
    _armadorController.dispose();
    super.dispose();
  }



  /// Buscar placas de forma incremental
  Future<void> _buscarPlacas(String query) async {
    print('🔍 [SEGUNDO_CONTEO] Iniciando búsqueda de placas con query: "$query"');

    if (query.isEmpty) {
      print('📝 [SEGUNDO_CONTEO] Query vacío, ocultando sugerencias');
      _ocultarSugerencias();
      return;
    }

    if (query.length < 2) {
      print('📝 [SEGUNDO_CONTEO] Query muy corto (${query.length} caracteres), esperando más texto');
      return;
    }

    try {
      print('🔄 [SEGUNDO_CONTEO] Llamando a FirebaseService.buscarPlacas...');
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final placas = await firebaseService.buscarPlacas(query);

      print('📊 [SEGUNDO_CONTEO] Placas encontradas: ${placas.length}');
      for (int i = 0; i < placas.length; i++) {
        print('  ${i + 1}. ${placas[i]}');
      }

      if (mounted) {
        setState(() {
          _placasSugeridas = placas;
        });

        if (placas.isNotEmpty) {
          print('✅ [SEGUNDO_CONTEO] Mostrando sugerencias');
          _mostrarSugerencias();
        } else {
          print('❌ [SEGUNDO_CONTEO] No hay placas, ocultando sugerencias');
          _ocultarSugerencias();
        }
      }
    } catch (e, stackTrace) {
      print('❌ [SEGUNDO_CONTEO] Error buscando placas: $e');
      print('📍 [SEGUNDO_CONTEO] StackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error buscando VH: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostrar overlay con sugerencias de placas
  void _mostrarSugerencias() {
    print('🎯 [SEGUNDO_CONTEO] Intentando mostrar sugerencias...');
    _ocultarSugerencias(); // Limpiar overlay anterior

    if (_placasSugeridas.isEmpty) {
      print('❌ [SEGUNDO_CONTEO] No hay placas sugeridas para mostrar');
      return;
    }

    print('✅ [SEGUNDO_CONTEO] Mostrando overlay con ${_placasSugeridas.length} sugerencias');

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32, // Ancho responsive
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'VH encontrados (${_placasSugeridas.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _placasSugeridas.length,
                      itemBuilder: (context, index) {
                        final placa = _placasSugeridas[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            placa,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            _placaController.text = placa;
                            _ocultarSugerencias();
                            _validarPlaca();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _mostrandoSugerencias = true;
    });

    print('🎉 [SEGUNDO_CONTEO] Overlay insertado exitosamente, _mostrandoSugerencias = true');
  }

  /// Ocultar overlay de sugerencias
  void _ocultarSugerencias() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _mostrandoSugerencias = false;
      });
    }
  }

  void _validarPlaca() {
    // Validar entrada
    final validationResult = ValidationService.validatePlaca(_placaController.text);
    if (!validationResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationResult.errorMessage!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Sanitizar la placa
    final placaSanitizada = ValidationService.sanitizePlaca(_placaController.text);
    
    // Verificar si ya fue contada
    final yaContada = _vhContados.any((vh) => vh.placa == placaSanitizada);
    if (yaContada) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('VH $placaSanitizada ya fue contado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _placaValidada = true;
      _placaController.text = placaSanitizada;
    });

    // Mostrar confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('VH listo para conteo: $placaSanitizada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _calcularDiferenciaNovedad() {
    final alistado = int.tryParse(_alistadoController.text) ?? 0;
    final fisico = int.tryParse(_fisicoController.text) ?? 0;
    setState(() {
      _diferencia = fisico - alistado;
    });
  }

  void _limpiarFormulario() {
    setState(() {
      _placaController.clear();
      _vhProgramadosController.clear();
      _vhSalenController.clear();
      _placaValidada = false;
      _tieneNovedad = false;
      _tipoNovedad = 'Faltante';
      _novedadesActuales.clear();
    });
    _limpiarFormularioNovedad();

    // Enfocar el campo de placa para el siguiente VH
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
      _placaController.clear();
    });
  }

  void _limpiarFormularioNovedad() {
    _dtController.clear();
    _skuController.clear();
    _descripcionController.clear();
    _alistadoController.clear();
    _fisicoController.clear();
    _verificadoController.clear();
    _armadorController.clear();
    setState(() {
      _diferencia = 0;
      _tipoNovedad = 'Faltante';
    });
  }

  void _agregarNovedadCompleta() {
    // Validar campos obligatorios
    if (_dtController.text.isEmpty ||
        _skuController.text.isEmpty ||
        _descripcionController.text.isEmpty ||
        _alistadoController.text.isEmpty ||
        _fisicoController.text.isEmpty ||
        _armadorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final novedad = NovedadConteo(
      tipo: _tipoNovedad,
      dt: _dtController.text,
      sku: _skuController.text,
      descripcion: _descripcionController.text,
      alistado: int.parse(_alistadoController.text),
      fisico: int.parse(_fisicoController.text),
      diferencia: _diferencia,
      verificado: int.tryParse(_verificadoController.text) ?? 0,
      armador: _armadorController.text,
    );

    setState(() {
      _novedadesActuales.add(novedad);
    });

    _limpiarFormularioNovedad();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Novedad ${_tipoNovedad.toLowerCase()} agregada'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _eliminarNovedad(int index) {
    setState(() {
      _novedadesActuales.removeAt(index);
    });
  }

  void _agregarVhContado() async {
    if (!_placaValidada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero valida la placa del VH'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final vhConteo = VhSegundoConteo.create(
        placa: _placaController.text,
        verificadorUid: authService.user!.uid,
        verificadorNombre: authService.userModel!.nombre,
        tieneNovedad: _tieneNovedad,
        novedades: _tieneNovedad ? List.from(_novedadesActuales) : [],
      );

      setState(() {
        _vhContados.add(vhConteo);
      });

      _limpiarFormulario();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('VH ${vhConteo.placa} agregado al conteo (${_vhContados.length} VH contados)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Registrar error en métricas
      final metricsService = Provider.of<MetricsService>(context, listen: false);
      metricsService.recordError(
        errorType: e.runtimeType.toString(),
        screen: 'segundo_conteo_screen_agregar',
        description: 'Error al agregar VH al conteo: ${e.toString()}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _eliminarVhContado(int index) {
    final vh = _vhContados[index];
    setState(() {
      _vhContados.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('VH ${vh.placa} eliminado del conteo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _finalizarSesion() async {
    if (_vhContados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay VH contados para guardar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Segundo Conteo'),
        content: Text('¿Confirmas finalizar el segundo conteo con ${_vhContados.length} VH?'),
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

    if (confirmar != true) return;

    // Guardar en Firebase
    if (!mounted) return;
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final metricsService = Provider.of<MetricsService>(context, listen: false);

    try {
      for (final vh in _vhContados) {
        await firebaseService.guardarSegundoConteo(vh);
      }

      // Registrar métricas de conteos exitosos
      final tiempoSesion = _inicioSesion != null
          ? DateTime.now().difference(_inicioSesion!)
          : const Duration(minutes: 10); // Tiempo por defecto

      for (final vh in _vhContados) {
        metricsService.recordConteo(
          vhId: vh.placa,
          productosContados: vh.novedades.length,
          tieneNovedades: vh.tieneNovedad,
          tiempoConteo: Duration(
            milliseconds: (tiempoSesion.inMilliseconds / _vhContados.length).round()
          ), // Tiempo promedio por VH
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Segundo conteo finalizado: ${_vhContados.length} VH guardados'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Registrar error en métricas
      if (mounted) {
        metricsService.recordError(
          errorType: e.runtimeType.toString(),
          screen: 'segundo_conteo_screen_finalizar',
          description: 'Error al guardar segundo conteo: ${e.toString()}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Ocultar sugerencias al tocar fuera del campo
        _ocultarSugerencias();
        // Quitar foco del campo de texto
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Segundo Conteo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_vhContados.isNotEmpty)
            IconButton(
              onPressed: _finalizarSesion,
              icon: const Icon(Icons.save),
              tooltip: 'Finalizar Conteo',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSesion(),
              const SizedBox(height: 16),
              _buildFormularioVh(),
              if (_placaValidada) ...[
                const SizedBox(height: 16),
                _buildSeccionNovedad(),
              ],
              if (_vhContados.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildListaVhContados(),
              ],
            ],
          ),
        ),
      ),
    ), // Cierre del Scaffold
    ); // Cierre del GestureDetector
  }

  Widget _buildInfoSesion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Información de la Sesión',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Fecha', DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ),
                Expanded(
                  child: _buildInfoItem('Tiempo', '00:00'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('VH Contados', '${_vhContados.length}'),
                ),
                Expanded(
                  child: _buildInfoItem('Con Novedades', '${_vhContados.where((vh) => vh.tieneNovedad).length}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDiferenciaVh() {
    final programados = int.tryParse(_vhProgramadosController.text) ?? 0;
    final salen = int.tryParse(_vhSalenController.text) ?? 0;
    final diferencia = salen - programados;

    Color color = Colors.grey;
    IconData icon = Icons.info;
    String mensaje = 'Sin diferencia';

    if (diferencia > 0) {
      color = Colors.orange;
      icon = Icons.trending_up;
      mensaje = '+$diferencia VH adicionales';
    } else if (diferencia < 0) {
      color = Colors.red;
      icon = Icons.trending_down;
      mensaje = '${diferencia.abs()} VH menos';
    } else if (programados > 0 && salen > 0) {
      color = Colors.green;
      icon = Icons.check_circle;
      mensaje = 'Coincide exactamente';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            mensaje,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioVh() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Nuevo VH',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: TextFormField(
                      controller: _placaController,
                      decoration: InputDecoration(
                        labelText: 'Placa del VH',
                        hintText: 'Escribe para buscar...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.directions_car),
                        suffixIcon: _mostrandoSugerencias
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _ocultarSugerencias,
                                tooltip: 'Cerrar sugerencias',
                              )
                            : _placaController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _placaController.clear();
                                      _ocultarSugerencias();
                                      setState(() {
                                        _placaValidada = false;
                                      });
                                    },
                                    tooltip: 'Limpiar',
                                  )
                                : const Icon(Icons.search, color: Colors.grey),
                        helperText: _placasSugeridas.isNotEmpty
                            ? '${_placasSugeridas.length} VH encontrados - Toca para seleccionar'
                            : 'Búsqueda automática mientras escribes',
                        helperStyle: TextStyle(
                          color: _placasSugeridas.isNotEmpty ? Colors.green : null,
                          fontWeight: _placasSugeridas.isNotEmpty ? FontWeight.w500 : null,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        setState(() {}); // Para actualizar el suffixIcon

                        // Búsqueda incremental con debounce
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (_placaController.text == value && mounted) {
                            _buscarPlacas(value);
                          }
                        });
                      },
                      onFieldSubmitted: (_) => _validarPlaca(),
                      onTap: () {
                        if (_placaController.text.isNotEmpty) {
                          _buscarPlacas(_placaController.text);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _validarPlaca,
                  icon: const Icon(Icons.search),
                  label: const Text('Validar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            // Botón de prueba temporal para verificar overlay
            if (_placasSugeridas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 ${_placasSugeridas.length} VH encontrados:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: _placasSugeridas.map((placa) =>
                          GestureDetector(
                            onTap: () {
                              _placaController.text = placa;
                              _ocultarSugerencias();
                              _validarPlaca();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Text(
                                placa,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // Campos de VH Programados
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vhProgramadosController,
                    decoration: const InputDecoration(
                      labelText: 'VH Programados',
                      hintText: 'Cantidad programada',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                      suffixText: 'VH',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      setState(() {
                        // Actualizar UI para mostrar diferencia
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final cantidad = int.tryParse(value);
                      if (cantidad == null || cantidad < 0) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vhSalenController,
                    decoration: const InputDecoration(
                      labelText: 'VH que Salen',
                      hintText: 'Cantidad real',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.exit_to_app),
                      suffixText: 'VH',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      setState(() {
                        // Actualizar UI para mostrar diferencia
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final cantidad = int.tryParse(value);
                      if (cantidad == null || cantidad < 0) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            // Mostrar diferencia si hay valores
            if (_vhProgramadosController.text.isNotEmpty && _vhSalenController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildDiferenciaVh(),
              ),

            if (_placaValidada) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'VH ${_placaController.text} listo para conteo',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _agregarVhContado,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar VH al Conteo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionNovedad() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '¿Novedad?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Sí'),
                    value: true,
                    groupValue: _tieneNovedad,
                    onChanged: (value) {
                      setState(() {
                        _tieneNovedad = value!;
                        if (!_tieneNovedad) {
                          _novedadesActuales.clear();
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('No'),
                    value: false,
                    groupValue: _tieneNovedad,
                    onChanged: (value) {
                      setState(() {
                        _tieneNovedad = value!;
                        if (!_tieneNovedad) {
                          _novedadesActuales.clear();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),

            // Formulario de novedad si se seleccionó "Sí"
            if (_tieneNovedad) ...[
              const SizedBox(height: 16),
              _buildFormularioNovedad(),
            ],

            // Lista de novedades agregadas
            if (_novedadesActuales.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildListaNovedades(),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _agregarVhContado,
                icon: const Icon(Icons.add),
                label: const Text('Agregar VH al Conteo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioNovedad() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalles de la Novedad',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Tipo de novedad
          Row(
            children: [
              const Text('Tipo: ', style: TextStyle(fontWeight: FontWeight.w600)),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Faltante'),
                        value: 'Faltante',
                        groupValue: _tipoNovedad,
                        onChanged: (value) {
                          setState(() {
                            _tipoNovedad = value!;
                          });
                        },
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Sobrante'),
                        value: 'Sobrante',
                        groupValue: _tipoNovedad,
                        onChanged: (value) {
                          setState(() {
                            _tipoNovedad = value!;
                          });
                        },
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campos del formulario según el súper prompt
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dtController,
                  decoration: const InputDecoration(
                    labelText: 'DT',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _descripcionController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _alistadoController,
                  decoration: const InputDecoration(
                    labelText: 'Alistado',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _calcularDiferenciaNovedad(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _fisicoController,
                  decoration: const InputDecoration(
                    labelText: 'Físico',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _calcularDiferenciaNovedad(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _diferencia == 0
                        ? Colors.green.shade100
                        : _diferencia > 0
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _diferencia == 0
                          ? Colors.green
                          : _diferencia > 0
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Diferencia',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _diferencia.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _diferencia == 0
                              ? Colors.green.shade800
                              : _diferencia > 0
                                  ? Colors.orange.shade800
                                  : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _verificadoController,
                  decoration: const InputDecoration(
                    labelText: 'Verificado (primer conteo)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _armadorController,
                  decoration: const InputDecoration(
                    labelText: 'Armador',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _agregarNovedadCompleta,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Novedad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _limpiarFormularioNovedad,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaNovedades() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Novedades Agregadas (${_novedadesActuales.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(_novedadesActuales.length, (index) {
          final novedad = _novedadesActuales[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: novedad.tipo == 'Faltante' ? Colors.red : Colors.orange,
                child: Text(
                  novedad.tipo[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text('${novedad.sku} - ${novedad.descripcion}'),
              subtitle: Text('DT: ${novedad.dt} | Dif: ${novedad.diferencia} | Armador: ${novedad.armador}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _eliminarNovedad(index),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildListaVhContados() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'VH Contados (${_vhContados.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_vhContados.length, (index) {
              final vh = _vhContados[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: vh.tieneNovedad ? Colors.orange : Colors.green,
                    child: Text(
                      vh.placa.substring(0, 2),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  title: Text(
                    vh.placa,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    vh.tieneNovedad
                        ? '${vh.novedades.length} novedad(es) - ${DateFormat('HH:mm').format(vh.timestamp)}'
                        : 'Sin novedades - ${DateFormat('HH:mm').format(vh.timestamp)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (vh.tieneNovedad)
                        const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarVhContado(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_vhContados.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _finalizarSesion,
                  icon: const Icon(Icons.save),
                  label: Text('Finalizar Conteo (${_vhContados.length} VH)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

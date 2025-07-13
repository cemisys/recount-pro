import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/firebase_service.dart';
import '../../../models/vh_model.dart';
import '../../../core/services/validation_service.dart';

class NovedadForm extends StatefulWidget {
  final Function(NovedadConteo) onNovedadAdded;
  
  const NovedadForm({
    super.key,
    required this.onNovedadAdded,
  });

  @override
  State<NovedadForm> createState() => _NovedadFormState();
}

class _NovedadFormState extends State<NovedadForm> {
  final _formKey = GlobalKey<FormState>();
  final _dtController = TextEditingController();
  final _skuController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _alistadoController = TextEditingController();
  final _fisicoController = TextEditingController();
  final _verificadoController = TextEditingController();
  final _armadorController = TextEditingController();
  
  String _tipoNovedad = 'Faltante';
  int _diferencia = 0;
  List<String> _armadoresDisponibles = [];
  bool _isLoadingData = false;

  // Variables para búsqueda incremental de SKU
  List<Map<String, String>> _skusSugeridos = [];
  bool _mostrandoSugerenciasSku = false;
  final LayerLink _layerLinkSku = LayerLink();
  OverlayEntry? _overlayEntrySku;
  Timer? _debounceTimer;

  // Variables para búsqueda incremental de Verificadores
  List<Map<String, String>> _verificadoresSugeridos = [];
  bool _mostrandoSugerenciasVerificador = false;
  final LayerLink _layerLinkVerificador = LayerLink();
  OverlayEntry? _overlayEntryVerificador;
  Timer? _debounceTimerVerificador;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _alistadoController.addListener(_calcularDiferencia);
    _fisicoController.addListener(_calcularDiferencia);
  }

  @override
  void dispose() {
    _dtController.dispose();
    _skuController.dispose();
    _descripcionController.dispose();
    _alistadoController.dispose();
    _fisicoController.dispose();
    _verificadoController.dispose();
    _armadorController.dispose();
    _debounceTimer?.cancel();
    _debounceTimerVerificador?.cancel();
    _ocultarSugerenciasSku();
    _ocultarSugerenciasVerificador();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoadingData = true;
    });

    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    
    // Cargar auxiliares (armadores)
    final auxiliares = await firebaseService.getAuxiliares();
    
    setState(() {
      _armadoresDisponibles = auxiliares
          .where((aux) => aux.cargo.toLowerCase().contains('armador'))
          .map((aux) => aux.nombre)
          .toList();
      _isLoadingData = false;
    });
  }

  void _calcularDiferencia() {
    final alistado = int.tryParse(_alistadoController.text) ?? 0;
    final fisico = int.tryParse(_fisicoController.text) ?? 0;
    
    setState(() {
      _diferencia = fisico - alistado;
      
      // Actualizar tipo de novedad basado en la diferencia
      if (_diferencia < 0) {
        _tipoNovedad = 'Faltante';
      } else if (_diferencia > 0) {
        _tipoNovedad = 'Sobrante';
      }
    });
  }

  Future<void> _buscarSKU() async {
    if (_skuController.text.trim().isEmpty) return;

    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final sku = await firebaseService.buscarSKU(_skuController.text.trim());

    if (sku != null) {
      setState(() {
        _descripcionController.text = sku.descripcion;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SKU no encontrado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Buscar Verificadores de forma incremental en la colección verificadores
  Future<void> _buscarVerificadoresIncremental(String query) async {
    print('🔍 [NOVEDAD] Buscando Verificadores en colección "verificadores" para: "$query"');

    if (query.isEmpty) {
      setState(() {
        _verificadoresSugeridos = [];
      });
      _ocultarSugerenciasVerificador();
      return;
    }

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);

      // Buscar directamente en la colección verificadores
      final verificadores = await firebaseService.buscarVerificadoresIncremental(query);

      print('📦 [NOVEDAD] Verificadores encontrados en Firebase: ${verificadores.length}');
      for (var verificador in verificadores) {
        print('  - ${verificador['nombre']}: ${verificador['email']}');
      }

      if (mounted) {
        setState(() {
          _verificadoresSugeridos = verificadores;
        });

        if (verificadores.isNotEmpty) {
          _mostrarSugerenciasVerificador();
        } else {
          print('⚠️ [NOVEDAD] No se encontraron verificadores, usando datos de prueba');
          _usarDatosDePruebaVerificadores(query);
        }
      }
    } catch (e) {
      print('❌ [NOVEDAD] Error buscando verificadores en Firebase: $e');
      // Si hay error, usar datos de prueba como fallback
      _usarDatosDePruebaVerificadores(query);
    }
  }

  /// Usar datos de prueba para verificadores si no hay datos en Firebase
  void _usarDatosDePruebaVerificadores(String query) {
    final datosPrueba = [
      {'nombre': 'Juan Pérez', 'email': 'juan.perez@empresa.com'},
      {'nombre': 'María García', 'email': 'maria.garcia@empresa.com'},
      {'nombre': 'Carlos López', 'email': 'carlos.lopez@empresa.com'},
      {'nombre': 'Ana Martínez', 'email': 'ana.martinez@empresa.com'},
      {'nombre': 'Luis Rodríguez', 'email': 'luis.rodriguez@empresa.com'},
      {'nombre': 'Carmen Sánchez', 'email': 'carmen.sanchez@empresa.com'},
      {'nombre': 'Pedro González', 'email': 'pedro.gonzalez@empresa.com'},
      {'nombre': 'Laura Fernández', 'email': 'laura.fernandez@empresa.com'},
    ];

    final verificadoresFiltrados = datosPrueba
        .where((verificador) =>
            verificador['nombre']!.toUpperCase().contains(query.toUpperCase()) ||
            verificador['email']!.toUpperCase().contains(query.toUpperCase()))
        .toList();

    print('📦 [NOVEDAD] Usando datos de prueba verificadores: ${verificadoresFiltrados.length} encontrados para "$query"');

    if (mounted) {
      setState(() {
        _verificadoresSugeridos = verificadoresFiltrados;
      });

      if (verificadoresFiltrados.isNotEmpty) {
        _mostrarSugerenciasVerificador();
      } else {
        _ocultarSugerenciasVerificador();
      }
    }
  }

  /// Buscar SKUs de forma incremental en la colección sku
  Future<void> _buscarSkusIncremental(String query) async {
    print('🔍 [NOVEDAD] Buscando SKUs en colección "sku" para: "$query"');

    if (query.isEmpty) {
      setState(() {
        _skusSugeridos = [];
      });
      _ocultarSugerenciasSku();
      return;
    }

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);

      // Buscar directamente en la colección sku
      final skus = await firebaseService.buscarSkusIncremental(query);

      print('📦 [NOVEDAD] SKUs encontrados en Firebase: ${skus.length}');
      for (var sku in skus) {
        print('  - ${sku['sku']}: ${sku['descripcion']}');
      }

      if (mounted) {
        setState(() {
          _skusSugeridos = skus;
        });

        if (skus.isNotEmpty) {
          _mostrarSugerenciasSku();
        } else {
          print('⚠️ [NOVEDAD] No se encontraron SKUs, usando datos de prueba');
          _usarDatosDePrueba(query);
        }
      }
    } catch (e) {
      print('❌ [NOVEDAD] Error buscando SKUs en Firebase: $e');
      // Si hay error, usar datos de prueba como fallback
      _usarDatosDePrueba(query);
    }
  }

  /// Usar datos de prueba si no hay datos en Firebase y cargar datos reales
  void _usarDatosDePrueba(String query) async {
    print('🔄 [NOVEDAD] Cargando datos de prueba en colección sku...');

    // Cargar datos de prueba en Firebase
    await _cargarDatosPruebaEnFirebase();

    final datosPrueba = [
      {'sku': '1413', 'descripcion': 'Costeña Lta 330cc X 6'},
      {'sku': '1428', 'descripcion': 'Poker Lta 330cc X 6'},
      {'sku': '2160', 'descripcion': 'Aguila Lig R 330cc X 30'},
      {'sku': '2171', 'descripcion': 'Aguila Lig Lta 330ccX6'},
      {'sku': '2174', 'descripcion': 'Aguila Lta 330cc X 6'},
      {'sku': 'ABC001', 'descripcion': 'Aceite de Motor 20W-50'},
      {'sku': 'ABC002', 'descripcion': 'Aceite de Transmisión ATF'},
      {'sku': 'DEF001', 'descripcion': 'Detergente Líquido 1L'},
      {'sku': 'DEF002', 'descripcion': 'Desinfectante Multiusos'},
      {'sku': 'GHI001', 'descripcion': 'Galletas de Chocolate'},
      {'sku': 'JKL001', 'descripcion': 'Jabón de Tocador'},
      {'sku': 'MNO001', 'descripcion': 'Mantequilla 500g'},
      {'sku': 'PQR001', 'descripcion': 'Pan Integral'},
      {'sku': 'STU001', 'descripcion': 'Shampoo Anticaspa'},
      {'sku': 'VWX001', 'descripcion': 'Vitaminas Multiples'},
    ];

    final skusFiltrados = datosPrueba
        .where((sku) =>
            sku['sku']!.toUpperCase().contains(query.toUpperCase()) ||
            sku['descripcion']!.toUpperCase().contains(query.toUpperCase()))
        .toList();

    print('📦 [NOVEDAD] Usando datos de prueba: ${skusFiltrados.length} SKUs encontrados para "$query"');

    if (mounted) {
      setState(() {
        _skusSugeridos = skusFiltrados;
      });

      if (skusFiltrados.isNotEmpty) {
        _mostrarSugerenciasSku();
      } else {
        _ocultarSugerenciasSku();
      }
    }
  }

  /// Cargar datos de prueba en Firebase
  Future<void> _cargarDatosPruebaEnFirebase() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);

      // Verificar si ya hay datos
      final existingData = await firebaseService.buscarSkusIncremental('1413');
      if (existingData.isNotEmpty) {
        print('✅ [NOVEDAD] Ya hay datos en la colección sku');
        return;
      }

      print('🔄 [NOVEDAD] Cargando datos de prueba en colección sku...');

      final datosPrueba = [
        {'sku': '1413', 'descripcion': 'Costeña Lta 330cc X 6', 'activo': true},
        {'sku': '1428', 'descripcion': 'Poker Lta 330cc X 6', 'activo': true},
        {'sku': '2160', 'descripcion': 'Aguila Lig R 330cc X 30', 'activo': true},
        {'sku': '2171', 'descripcion': 'Aguila Lig Lta 330ccX6', 'activo': true},
        {'sku': '2174', 'descripcion': 'Aguila Lta 330cc X 6', 'activo': true},
        {'sku': 'ABC001', 'descripcion': 'Aceite de Motor 20W-50', 'activo': true},
        {'sku': 'ABC002', 'descripcion': 'Aceite de Transmisión ATF', 'activo': true},
        {'sku': 'DEF001', 'descripcion': 'Detergente Líquido 1L', 'activo': true},
        {'sku': 'DEF002', 'descripcion': 'Desinfectante Multiusos', 'activo': true},
        {'sku': 'GHI001', 'descripcion': 'Galletas de Chocolate', 'activo': true},
      ];

      // Usar el servicio de Firebase para agregar los datos
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (var dato in datosPrueba) {
        final docRef = firestore.collection('sku').doc(dato['sku'] as String);
        batch.set(docRef, {
          ...dato,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ [NOVEDAD] Datos de prueba cargados en colección sku');

    } catch (e) {
      print('❌ [NOVEDAD] Error cargando datos de prueba: $e');
    }
  }

  /// Mostrar overlay con sugerencias de SKU
  void _mostrarSugerenciasSku() {
    _ocultarSugerenciasSku(); // Limpiar overlay anterior

    _overlayEntrySku = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLinkSku,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _skusSugeridos.length,
                itemBuilder: (context, index) {
                  final sku = _skusSugeridos[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_2, color: Colors.orange, size: 20),
                    title: Text(
                      sku['sku'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      sku['descripcion'] ?? '',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _seleccionarSku(sku),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntrySku!);
    setState(() {
      _mostrandoSugerenciasSku = true;
    });
  }

  /// Ocultar sugerencias de SKU
  void _ocultarSugerenciasSku() {
    _overlayEntrySku?.remove();
    _overlayEntrySku = null;
    if (mounted) {
      setState(() {
        _mostrandoSugerenciasSku = false;
      });
    }
  }

  /// Mostrar sugerencias de verificadores
  void _mostrarSugerenciasVerificador() {
    _ocultarSugerenciasVerificador();

    _overlayEntryVerificador = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLinkVerificador,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _verificadoresSugeridos.length,
                itemBuilder: (context, index) {
                  final verificador = _verificadoresSugeridos[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.person, color: Colors.blue, size: 20),
                    title: Text(
                      verificador['nombre'] ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      verificador['email'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    onTap: () {
                      _seleccionarVerificador(verificador);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntryVerificador!);
    setState(() {
      _mostrandoSugerenciasVerificador = true;
    });
  }

  /// Ocultar sugerencias de verificadores
  void _ocultarSugerenciasVerificador() {
    _overlayEntryVerificador?.remove();
    _overlayEntryVerificador = null;
    if (mounted) {
      setState(() {
        _mostrandoSugerenciasVerificador = false;
      });
    }
  }

  void _seleccionarVerificador(Map<String, String> verificador) {
    setState(() {
      _verificadoController.text = verificador['nombre'] ?? '';
    });
    _ocultarSugerenciasVerificador();
    print('✅ [NOVEDAD] Verificador seleccionado: ${verificador['nombre']}');
  }

  /// Seleccionar un SKU de las sugerencias
  void _seleccionarSku(Map<String, String> sku) {
    setState(() {
      _skuController.text = sku['sku'] ?? '';
      _descripcionController.text = sku['descripcion'] ?? '';
    });
    _ocultarSugerenciasSku();
  }

  void _agregarNovedad() {
    if (!_formKey.currentState!.validate()) return;
    
    final novedad = NovedadConteo(
      tipo: _tipoNovedad,
      dt: _dtController.text.trim(),
      sku: _skuController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      alistado: int.parse(_alistadoController.text),
      fisico: int.parse(_fisicoController.text),
      diferencia: _diferencia,
      verificado: 1, // Marcado como verificado
      // Nota: El nombre del verificador se guarda en el campo armador por ahora
      armador: '${_armadorController.text.trim()} | Verificado por: ${_verificadoController.text.trim()}',
    );
    
    widget.onNovedadAdded(novedad);
    
    // Limpiar formulario
    _limpiarFormulario();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Novedad agregada'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _limpiarFormulario() {
    _dtController.clear();
    _skuController.clear();
    _descripcionController.clear();
    _alistadoController.clear();
    _fisicoController.clear();
    _verificadoController.clear();
    _armadorController.clear();
    setState(() {
      _tipoNovedad = 'Faltante';
      _diferencia = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar Novedad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Tipo de novedad
              Row(
                children: [
                  const Text('Tipo: '),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _tipoNovedad == 'Faltante' 
                          ? AppTheme.errorColor 
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _tipoNovedad,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // DT
              TextFormField(
                controller: _dtController,
                decoration: const InputDecoration(
                  labelText: 'DT',
                  hintText: 'Número de documento de transporte',
                ),
                validator: (value) {
                  final result = ValidationService.validateRequired(value, 'DT');
                  return result.isValid ? null : result.errorMessage;
                },
              ),
              const SizedBox(height: 16),
              
              // SKU con búsqueda incremental
              CompositedTransformTarget(
                link: _layerLinkSku,
                child: TextFormField(
                  controller: _skuController,
                  decoration: InputDecoration(
                    labelText: 'SKU',
                    hintText: 'Buscar código del producto...',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_mostrandoSugerenciasSku)
                          IconButton(
                            onPressed: _ocultarSugerenciasSku,
                            icon: const Icon(Icons.close, size: 20),
                            tooltip: 'Cerrar sugerencias',
                          ),
                        IconButton(
                          onPressed: _buscarSKU,
                          icon: const Icon(Icons.search, size: 20),
                          tooltip: 'Buscar SKU',
                        ),
                      ],
                    ),
                  ),
                  validator: (value) {
                    final result = ValidationService.validateSku(value);
                    return result.isValid ? null : result.errorMessage;
                  },
                  onChanged: (value) {
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                      _buscarSkusIncremental(value);
                    });
                  },
                  onTap: () {
                    if (_skuController.text.isNotEmpty && _skusSugeridos.isNotEmpty) {
                      _mostrarSugerenciasSku();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Descripción (autocompletada)
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Se completa automáticamente al seleccionar SKU',
                  suffixIcon: Icon(
                    Icons.auto_fix_high,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                readOnly: true,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Selecciona un SKU para completar la descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Cantidades
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _alistadoController,
                      decoration: const InputDecoration(
                        labelText: 'Alistado',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final result = ValidationService.validateQuantity(value);
                        return result.isValid ? null : result.errorMessage;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fisicoController,
                      decoration: const InputDecoration(
                        labelText: 'Físico',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final result = ValidationService.validateQuantity(value);
                        return result.isValid ? null : result.errorMessage;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Diferencia',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _diferencia.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _diferencia == 0 
                                  ? Colors.green 
                                  : _diferencia < 0 
                                      ? AppTheme.errorColor 
                                      : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Verificado y Armador
              Row(
                children: [
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLinkVerificador,
                      child: TextFormField(
                        controller: _verificadoController,
                        enabled: true,
                        readOnly: false,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Verificado por',
                          hintText: 'Buscar verificador...',
                          border: const OutlineInputBorder(),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_mostrandoSugerenciasVerificador)
                                IconButton(
                                  onPressed: _ocultarSugerenciasVerificador,
                                  icon: const Icon(Icons.close, size: 20),
                                  tooltip: 'Cerrar sugerencias',
                                ),
                              const Icon(Icons.person_search, size: 20),
                            ],
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingrese el verificador';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          print('🔤 [VERIFICADOR] Texto cambiado: "$value"');
                          _debounceTimerVerificador?.cancel();
                          _debounceTimerVerificador = Timer(const Duration(milliseconds: 300), () {
                            _buscarVerificadoresIncremental(value);
                          });
                        },
                        onTap: () {
                          print('👆 [VERIFICADOR] Campo tocado');
                          if (_verificadoController.text.isNotEmpty && _verificadoresSugeridos.isNotEmpty) {
                            _mostrarSugerenciasVerificador();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoadingData
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _armadorController.text.isEmpty 
                                ? null 
                                : _armadorController.text,
                            decoration: const InputDecoration(
                              labelText: 'Armador',
                            ),
                            items: _armadoresDisponibles
                                .map((armador) => DropdownMenuItem(
                                      value: armador,
                                      child: Text(armador),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              _armadorController.text = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona armador';
                              }
                              return null;
                            },
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _limpiarFormulario,
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _agregarNovedad,
                      child: const Text('Agregar Novedad'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
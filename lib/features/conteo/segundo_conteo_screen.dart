import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/vh_model.dart';
import '../../core/services/validation_service.dart';
import '../../core/services/metrics_service.dart';

class SegundoConteoScreen extends StatefulWidget {
  const SegundoConteoScreen({super.key});

  @override
  State<SegundoConteoScreen> createState() => _SegundoConteoScreenState();
}

class _SegundoConteoScreenState extends State<SegundoConteoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _vhProgramadosController = TextEditingController();
  final _cantidadVhController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Variables para la sesión de segundo conteo
  bool _isLoading = false;
  DateTime? _inicioConteo;

  // Variables para el VH actual
  bool _tieneNovedad = false;
  VhProgramado? _vhSeleccionado;
  List<ProductoSegundoConteo> _productosConteo = [];
  final List<NovedadConteo> _novedades = [];
  bool _isGuardando = false;
  String _tipoNovedad = 'Faltante';
  final _dtController = TextEditingController();
  final _skuController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _alistadoController = TextEditingController();
  final _fisicoController = TextEditingController();
  final _verificadoController = TextEditingController();
  final _armadorController = TextEditingController();

  int _diferencia = 0;
  
  @override
  void dispose() {
    _placaController.dispose();
    _dtController.dispose();
    _skuController.dispose();
    _descripcionController.dispose();
    _alistadoController.dispose();
    _fisicoController.dispose();
    _verificadoController.dispose();
    _armadorController.dispose();
    super.dispose();
  }



  Future<void> _buscarVhPorPlaca() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final vh = await firebaseService.buscarVhPorPlaca(_placaController.text.trim());

      setState(() {
        _isLoading = false;
      });

      if (vh != null) {
        setState(() {
          _vhSeleccionado = vh;
        });

        // Inicializar tiempo de conteo para métricas
        _inicioConteo = DateTime.now();

        _inicializarProductosConteo(vh);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('VH no encontrado para la fecha actual'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Registrar error en métricas
      if (mounted) {
        final metricsService = Provider.of<MetricsService>(context, listen: false);
        metricsService.recordError(
          errorType: e.runtimeType.toString(),
          screen: 'segundo_conteo_screen_busqueda',
          description: 'Error al buscar VH: ${e.toString()}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar VH: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _inicializarProductosConteo(VhProgramado vh) {
    setState(() {
      _productosConteo = vh.productos.map((producto) => 
        ProductoSegundoConteo(
          sku: producto.sku,
          descripcion: producto.descripcion,
          cantidadProgramada: producto.cantidadProgramada,
          cantidadContada: producto.cantidadProgramada, // Inicializar con cantidad programada
          unidad: producto.unidad,
        )
      ).toList();
    });
  }

  void _actualizarCantidadContada(int index, int nuevaCantidad) {
    setState(() {
      _productosConteo[index] = ProductoSegundoConteo(
        sku: _productosConteo[index].sku,
        descripcion: _productosConteo[index].descripcion,
        cantidadProgramada: _productosConteo[index].cantidadProgramada,
        cantidadContada: nuevaCantidad,
        unidad: _productosConteo[index].unidad,
        observaciones: _productosConteo[index].observaciones,
      );
    });
  }

  Future<void> _guardarSegundoConteo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vhSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero busca un VH válido'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_vhProgramadosController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la cantidad de VH programados'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_cantidadVhController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la cantidad de VH que salen'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Validar novedades si se indicó que las hay
    if (_tieneNovedad && _novedades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos una novedad o cambiar a "No tiene novedad"'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isGuardando = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final metricsService = Provider.of<MetricsService>(context, listen: false);

    try {
      final segundoConteo = VhSegundoConteo.create(
        placa: _vhSeleccionado!.placa,
        verificadorUid: authService.user!.uid,
        verificadorNombre: authService.userModel!.nombre,
        tieneNovedad: _tieneNovedad,
        novedades: _tieneNovedad ? _novedades : [],
        observaciones: _observacionesController.text.isNotEmpty
            ? _observacionesController.text
            : null,
      );

      final success = await firebaseService.guardarSegundoConteo(segundoConteo);

      setState(() {
        _isGuardando = false;
      });

      if (success && mounted) {
        // Calcular tiempo de conteo
        final tiempoConteo = _inicioConteo != null
            ? DateTime.now().difference(_inicioConteo!)
            : const Duration(minutes: 8); // Tiempo por defecto

        // Registrar conteo exitoso en métricas
        metricsService.recordConteo(
          vhId: _vhSeleccionado!.placa,
          productosContados: _novedades.length,
          tieneNovedades: _tieneNovedad,
          tiempoConteo: tiempoConteo,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Segundo conteo guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _limpiarFormulario();
      } else if (mounted) {
        // Registrar error en métricas
        metricsService.recordError(
          errorType: 'SaveError',
          screen: 'segundo_conteo_screen_guardar',
          description: 'Error al guardar segundo conteo en Firebase',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el segundo conteo'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGuardando = false;
      });

      // Registrar error en métricas
      if (mounted) {
        metricsService.recordError(
          errorType: e.runtimeType.toString(),
          screen: 'segundo_conteo_screen_guardar',
          description: 'Excepción al guardar segundo conteo: ${e.toString()}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _placaController.clear();
      _cantidadVhController.clear();
      _vhProgramadosController.clear();
      _observacionesController.clear();
      _vhSeleccionado = null;
      _productosConteo.clear();
      _tieneNovedad = false;
      _novedades.clear();
    });
  }



  void _eliminarNovedad(int index) {
    setState(() {
      _novedades.removeAt(index);
    });
  }

  void _calcularDiferenciaNovedad() {
    final alistado = int.tryParse(_alistadoController.text) ?? 0;
    final fisico = int.tryParse(_fisicoController.text) ?? 0;
    setState(() {
      _diferencia = fisico - alistado;
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

  // Métodos para calcular y mostrar diferencias de VH
  String _calcularDiferencia() {
    final programados = int.tryParse(_vhProgramadosController.text) ?? 0;
    final salen = int.tryParse(_cantidadVhController.text) ?? 0;
    final diferencia = salen - programados;

    if (diferencia > 0) {
      return '+$diferencia VH';
    } else if (diferencia < 0) {
      return '$diferencia VH';
    } else {
      return 'Sin diferencia';
    }
  }

  Color _getDiferenciaColor() {
    final programados = int.tryParse(_vhProgramadosController.text) ?? 0;
    final salen = int.tryParse(_cantidadVhController.text) ?? 0;
    final diferencia = salen - programados;

    if (diferencia > 0) {
      return Colors.orange; // Más VH de los programados
    } else if (diferencia < 0) {
      return Colors.red; // Menos VH de los programados
    } else {
      return Colors.green; // Exactamente los programados
    }
  }

  IconData _getDiferenciaIcon() {
    final programados = int.tryParse(_vhProgramadosController.text) ?? 0;
    final salen = int.tryParse(_cantidadVhController.text) ?? 0;
    final diferencia = salen - programados;

    if (diferencia > 0) {
      return Icons.trending_up; // Más VH
    } else if (diferencia < 0) {
      return Icons.trending_down; // Menos VH
    } else {
      return Icons.check_circle; // Exacto
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segundo Conteo'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          if (_vhSeleccionado != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _limpiarFormulario,
              tooltip: 'Limpiar formulario',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Búsqueda de VH
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buscar VH Programado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _placaController,
                              decoration: const InputDecoration(
                                labelText: 'Placa del VH',
                                hintText: 'Ej: ABC123',
                                prefixIcon: Icon(Icons.local_shipping),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                final result = ValidationService.validatePlaca(value ?? '');
                                return result.isValid ? null : result.errorMessage;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _buscarVhPorPlaca,
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                            label: const Text('Buscar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información del VH encontrado
              if (_vhSeleccionado != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'VH Encontrado',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Placa', _vhSeleccionado!.placa),
                        _buildInfoRow('Fecha', DateFormat('dd/MM/yyyy').format(_vhSeleccionado!.fecha)),
                        _buildInfoRow('Total productos', '${_vhSeleccionado!.totalProductos}'),
                        if (_vhSeleccionado!.conductor != null)
                          _buildInfoRow('Conductor', _vhSeleccionado!.conductor!),
                        if (_vhSeleccionado!.ruta != null)
                          _buildInfoRow('Ruta', _vhSeleccionado!.ruta!),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sección de Novedades
                Card(
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
                              style: Theme.of(context).textTheme.titleMedium,
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
                                      _novedades.clear();
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
                        if (_novedades.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Novedades Registradas:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(_novedades.length, (index) {
                            final novedad = _novedades[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text('${novedad.tipo}: ${novedad.sku}'),
                                subtitle: Text(
                                  '${novedad.descripcion}\n'
                                  'DT: ${novedad.dt} | Alistado: ${novedad.alistado} | Físico: ${novedad.fisico}\n'
                                  'Diferencia: ${novedad.diferencia} | Armador: ${novedad.armador}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _eliminarNovedad(index),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Información de VH Programados
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'VH Programados',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _vhProgramadosController,
                                decoration: const InputDecoration(
                                  labelText: 'VH Programados',
                                  hintText: 'Cantidad programada',
                                  prefixIcon: Icon(Icons.schedule),
                                  suffixText: 'VH',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                autofocus: false,
                                enabled: true,
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      // Trigger rebuild to update difference calculation
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es requerido';
                                  }
                                  final cantidad = int.tryParse(value);
                                  if (cantidad == null || cantidad < 0) {
                                    return 'Ingresa una cantidad válida';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _cantidadVhController,
                                decoration: const InputDecoration(
                                  labelText: 'VH que Salen',
                                  hintText: 'Cantidad real',
                                  prefixIcon: Icon(Icons.exit_to_app),
                                  suffixText: 'VH',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                enabled: true,
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      // Trigger rebuild to update difference calculation
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Este campo es requerido';
                                  }
                                  final cantidad = int.tryParse(value);
                                  if (cantidad == null || cantidad < 0) {
                                    return 'Ingresa una cantidad válida';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Mostrar diferencia si hay datos
                        if (_vhProgramadosController.text.isNotEmpty && _cantidadVhController.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getDiferenciaColor().withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getDiferenciaColor()),
                            ),
                            child: Row(
                              children: [
                                Icon(_getDiferenciaIcon(), color: _getDiferenciaColor()),
                                const SizedBox(width: 8),
                                Text(
                                  'Diferencia: ${_calcularDiferencia()}',
                                  style: TextStyle(
                                    color: _getDiferenciaColor(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Lista de productos para conteo
                if (_productosConteo.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text(
                                'Productos a Contar',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(_productosConteo.length, (index) {
                            final producto = _productosConteo[index];
                            return _buildProductoConteoCard(producto, index);
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Observaciones
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Observaciones (Opcional)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _observacionesController,
                            decoration: const InputDecoration(
                              labelText: 'Observaciones',
                              hintText: 'Agrega cualquier observación relevante...',
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón guardar
                  ElevatedButton.icon(
                    onPressed: _isGuardando ? null : _guardarSegundoConteo,
                    icon: _isGuardando 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isGuardando ? 'Guardando...' : 'Guardar Segundo Conteo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildProductoConteoCard(ProductoSegundoConteo producto, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.sku,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        producto.descripcion,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: producto.tieneDiferencia 
                        ? (producto.diferencia > 0 ? Colors.orange : Colors.red)
                        : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    producto.tieneDiferencia 
                        ? '${producto.diferencia > 0 ? '+' : ''}${producto.diferencia}'
                        : 'OK',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Programado:', style: TextStyle(fontSize: 12)),
                      Text(
                        '${producto.cantidadProgramada}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: producto.cantidadContada.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad Contada',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final cantidad = int.tryParse(value) ?? 0;
                      _actualizarCantidadContada(index, cantidad);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el formulario de novedad según el súper prompt
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
      _novedades.add(novedad);
    });

    _limpiarFormularioNovedad();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Novedad ${_tipoNovedad.toLowerCase()} agregada'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

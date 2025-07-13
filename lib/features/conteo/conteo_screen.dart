import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/vh_model.dart';
import '../../core/services/validation_service.dart';
import '../../core/services/metrics_service.dart';
import 'widgets/novedad_form.dart';

class ConteoScreen extends StatefulWidget {
  const ConteoScreen({super.key});

  @override
  State<ConteoScreen> createState() => _ConteoScreenState();
}

class _ConteoScreenState extends State<ConteoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();

  VhProgramado? _vhSeleccionado;
  bool _tieneNovedad = false;
  final List<NovedadConteo> _novedades = [];
  bool _isLoading = false;

  // Para medir tiempo de conteo
  DateTime? _inicioConteo;
  
  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _buscarVhPorPlaca() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Sanitizar la placa
      final placaSanitizada = ValidationService.sanitizePlaca(_placaController.text);
      final vh = await firebaseService.getVhPorPlaca(placaSanitizada);

      setState(() {
        _vhSeleccionado = vh;
        _isLoading = false;
      });

      if (vh == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró VH programado con esa placa para hoy'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } else {
        // Iniciar medición de tiempo de conteo
        _inicioConteo = DateTime.now();

        // Verificar si ya fue contado
        final yaContado = await firebaseService.vhYaContado(
          vh.vhId,
          authService.user!.uid,
        );

        if (yaContado && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este VH ya fue contado hoy'),
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
          screen: 'conteo_screen_busqueda',
          description: 'Error al buscar VH: ${e.toString()}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar VH: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _guardarConteo() async {
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

    if (_tieneNovedad && _novedades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una novedad'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final metricsService = Provider.of<MetricsService>(context, listen: false);

    try {
      final conteo = ConteoVh(
        fecha: DateTime.now(),
        verificadorUid: authService.user!.uid,
        verificadorNombre: authService.userModel!.nombre,
        vhId: _vhSeleccionado!.vhId,
        placa: _vhSeleccionado!.placa,
        tieneNovedad: _tieneNovedad,
        novedades: _tieneNovedad ? _novedades : null,
        fechaCreacion: DateTime.now(),
      );

      final success = await firebaseService.guardarConteo(conteo);

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        // Calcular tiempo de conteo
        final tiempoConteo = _inicioConteo != null
            ? DateTime.now().difference(_inicioConteo!)
            : const Duration(minutes: 5); // Tiempo por defecto si no se midió

        // Registrar conteo exitoso en métricas
        metricsService.recordConteo(
          vhId: _vhSeleccionado!.vhId,
          productosContados: _vhSeleccionado!.productos.length,
          tieneNovedades: _tieneNovedad,
          tiempoConteo: tiempoConteo,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conteo guardado exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        // Registrar error en métricas
        metricsService.recordError(
          errorType: 'SaveError',
          screen: 'conteo_screen_guardar',
          description: 'Error al guardar conteo en Firebase',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el conteo'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Registrar error en métricas
      if (mounted) {
        metricsService.recordError(
          errorType: e.runtimeType.toString(),
          screen: 'conteo_screen_guardar',
          description: 'Excepción al guardar conteo: ${e.toString()}',
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

  void _agregarNovedad(NovedadConteo novedad) {
    setState(() {
      _novedades.add(novedad);
    });
  }

  void _eliminarNovedad(int index) {
    setState(() {
      _novedades.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segundo Conteo'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del verificador y fecha
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
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
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Verificador: ${authService.userModel?.nombre ?? "N/A"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Búsqueda de VH
              const Text(
                'Información del Vehículo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _placaController,
                      decoration: const InputDecoration(
                        labelText: 'Placa del VH',
                        prefixIcon: Icon(Icons.local_shipping),
                        hintText: 'Ej: ABC123',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        final result = ValidationService.validatePlaca(value);
                        return result.isValid ? null : result.errorMessage;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _buscarVhPorPlaca,
                    child: _isLoading
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
                        : const Text('Buscar'),
                  ),
                ],
              ),
              
              if (_vhSeleccionado != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VH Encontrado: ${_vhSeleccionado!.vhId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Placa: ${_vhSeleccionado!.placa}'),
                        Text('Productos: ${_vhSeleccionado!.productos.length}'),
                      ],
                    ),
                  ),
                ),

                // Lista de productos del VH
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Productos a Contar',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _vhSeleccionado!.productos.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final producto = _vhSeleccionado!.productos[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SKU: ${producto.sku}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          producto.descripcion,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${producto.cantidadProgramada}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        producto.unidad ?? 'UN',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Selector de novedad
              const Text(
                '¿Hay Novedad?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
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
                ],
              ),
              
              // Formulario de novedades
              if (_tieneNovedad) ...[
                const SizedBox(height: 20),
                NovedadForm(
                  onNovedadAdded: _agregarNovedad,
                ),
                
                if (_novedades.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Novedades Registradas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _novedades.length,
                    itemBuilder: (context, index) {
                      final novedad = _novedades[index];
                      return Card(
                        child: ListTile(
                          title: Text('${novedad.tipo}: ${novedad.sku}'),
                          subtitle: Text(
                            '${novedad.descripcion}\n'
                            'Diferencia: ${novedad.diferencia}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                            onPressed: () => _eliminarNovedad(index),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
              
              const SizedBox(height: 30),
              
              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarConteo,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Agregar VH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
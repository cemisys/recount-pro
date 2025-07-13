import 'package:flutter/material.dart';
import '../../../core/widgets/performance_widgets.dart';
import '../../../core/services/performance_service.dart';
import '../../../models/vh_model.dart';

/// Lista optimizada de conteos que usa widgets de performance
class OptimizedConteoList extends StatefulWidget {
  final List<VhProgramado> vhList;
  final Function(VhProgramado) onVhSelected;
  final bool enableAnimations;

  const OptimizedConteoList({
    super.key,
    required this.vhList,
    required this.onVhSelected,
    this.enableAnimations = true,
  });

  @override
  State<OptimizedConteoList> createState() => _OptimizedConteoListState();
}

class _OptimizedConteoListState extends State<OptimizedConteoList> {
  
  @override
  Widget build(BuildContext context) {
    return PerformanceMeasureWidget(
      measurementName: 'OptimizedConteoList',
      child: _buildOptimizedList(),
    );
  }

  Widget _buildOptimizedList() {
    if (widget.vhList.isEmpty) {
      return const Center(
        child: Text('No hay VH programados'),
      );
    }

    return OptimizedListView(
      itemCount: widget.vhList.length,
      itemBuilder: (context, index) {
        final vh = widget.vhList[index];
        return _buildVhItem(vh, index);
      },
      padding: const EdgeInsets.all(8),
    );
  }

  Widget _buildVhItem(VhProgramado vh, int index) {
    return LazyLoadWidget(
      preload: PerformanceService.shouldPreloadData(),
      placeholder: _buildPlaceholderItem(),
      builder: () => _buildActualVhItem(vh, index),
    );
  }

  Widget _buildPlaceholderItem() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildActualVhItem(VhProgramado vh, int index) {
    return OptimizedAnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: InkWell(
          onTap: () => widget.onVhSelected(vh),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildVhIcon(vh),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVhInfo(vh),
                ),
                _buildVhStatus(vh),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVhIcon(VhProgramado vh) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getVhStatusColor(vh).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.local_shipping,
        color: _getVhStatusColor(vh),
        size: 20,
      ),
    );
  }

  Widget _buildVhInfo(VhProgramado vh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VH: ${vh.vhId}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Placa: ${vh.placa}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${vh.productos.length} productos',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildVhStatus(VhProgramado vh) {
    final statusColor = _getVhStatusColor(vh);
    final statusText = _getVhStatusText(vh);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getVhStatusColor(VhProgramado vh) {
    if (vh.estado == null) {
      return Theme.of(context).colorScheme.primary;
    }
    
    switch (vh.estado!.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'en_proceso':
        return Colors.orange;
      case 'pendiente':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  String _getVhStatusText(VhProgramado vh) {
    if (vh.estado == null) {
      return 'Pendiente';
    }
    
    switch (vh.estado!.toLowerCase()) {
      case 'completado':
        return 'Completado';
      case 'en_proceso':
        return 'En Proceso';
      case 'pendiente':
        return 'Pendiente';
      default:
        return vh.estado!;
    }
  }
}

/// Widget optimizado para mostrar detalles de un producto
class OptimizedProductoItem extends StatelessWidget {
  final ProductoVh producto;
  final VoidCallback? onTap;

  const OptimizedProductoItem({
    super.key,
    required this.producto,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedAnimatedContainer(
      duration: PerformanceService.getAnimationDuration(const Duration(milliseconds: 200)),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.sku,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (producto.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          producto.descripcion,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${producto.cantidadProgramada}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de búsqueda optimizada
class OptimizedSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String? hintText;

  const OptimizedSearchBar({
    super.key,
    required this.onSearchChanged,
    this.hintText,
  });

  @override
  State<OptimizedSearchBar> createState() => _OptimizedSearchBarState();
}

class _OptimizedSearchBarState extends State<OptimizedSearchBar> {
  
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OptimizedAnimatedContainer(
      duration: PerformanceService.getAnimationDuration(const Duration(milliseconds: 200)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _controller,
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Buscar...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

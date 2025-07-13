import 'package:flutter/material.dart';
import '../services/performance_service.dart';

/// Widget de imagen optimizada que se adapta a la configuración de performance
class OptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;

  const OptimizedImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
  }) : assert(imageUrl != null || assetPath != null, 'Either imageUrl or assetPath must be provided');

  @override
  Widget build(BuildContext context) {
    final scaleFactor = PerformanceService.getImageScaleFactor();
    final effectiveWidth = width != null ? width! * scaleFactor : null;
    final effectiveHeight = height != null ? height! * scaleFactor : null;

    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        cacheWidth: effectiveWidth?.round(),
        cacheHeight: effectiveHeight?.round(),
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget!
            : null,
      );
    }

    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        cacheWidth: effectiveWidth?.round(),
        cacheHeight: effectiveHeight?.round(),
        loadingBuilder: placeholder != null
            ? (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder!;
              }
            : null,
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget!
            : null,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Widget de animación optimizada que respeta la configuración de performance
class OptimizedAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;

  const OptimizedAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.width,
    this.height,
    this.color,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final optimizedDuration = PerformanceService.getAnimationDuration(duration);

    if (optimizedDuration == Duration.zero) {
      // Si las animaciones están deshabilitadas, mostrar directamente el contenido
      return Container(
        width: width,
        height: height,
        color: color,
        padding: padding,
        margin: margin,
        decoration: decoration,
        alignment: alignment,
        child: child,
      );
    }

    return AnimatedContainer(
      duration: optimizedDuration,
      curve: curve,
      width: width,
      height: height,
      color: color,
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Widget de lista optimizada con lazy loading
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      cacheExtent: PerformanceService.lowMemoryMode ? 250.0 : 500.0,
      itemBuilder: (context, index) {
        // Envolver cada item en RepaintBoundary para optimizar repaints
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// Widget de transición optimizada
class OptimizedPageTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final PageTransitionType type;

  const OptimizedPageTransition({
    super.key,
    required this.child,
    required this.animation,
    this.type = PageTransitionType.slide,
  });

  @override
  Widget build(BuildContext context) {
    if (!PerformanceService.animationsEnabled) {
      return child;
    }

    switch (type) {
      case PageTransitionType.slide:
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
          ),
          child: child,
        );
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: animation,
          child: child,
        );
    }
  }
}

enum PageTransitionType { slide, fade, scale }

/// Widget de carga diferida (lazy loading)
class LazyLoadWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  final bool preload;

  const LazyLoadWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.preload = false,
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  Widget? _cachedWidget;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.preload && PerformanceService.shouldPreloadData()) {
      _loadWidget();
    }
  }

  void _loadWidget() {
    if (!_isLoaded) {
      setState(() {
        _cachedWidget = widget.builder();
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _cachedWidget != null) {
      return _cachedWidget!;
    }

    return GestureDetector(
      onTap: _loadWidget,
      child: widget.placeholder ??
          const Center(
            child: CircularProgressIndicator(),
          ),
    );
  }
}

/// Widget de caché de construcción para widgets costosos
class BuildCacheWidget extends StatefulWidget {
  final Widget Function() builder;
  final Duration cacheDuration;
  final String? cacheKey;

  const BuildCacheWidget({
    super.key,
    required this.builder,
    this.cacheDuration = const Duration(minutes: 5),
    this.cacheKey,
  });

  @override
  State<BuildCacheWidget> createState() => _BuildCacheWidgetState();
}

class _BuildCacheWidgetState extends State<BuildCacheWidget> {
  static final Map<String, _CacheEntry> _cache = {};
  
  Widget? _cachedWidget;
  DateTime? _cacheTime;
  String? _currentCacheKey;

  @override
  void initState() {
    super.initState();
    _currentCacheKey = widget.cacheKey ?? widget.hashCode.toString();
    _loadFromCache();
  }

  void _loadFromCache() {
    final cacheEntry = _cache[_currentCacheKey];
    if (cacheEntry != null && 
        DateTime.now().difference(cacheEntry.timestamp) < widget.cacheDuration) {
      _cachedWidget = cacheEntry.widget;
      _cacheTime = cacheEntry.timestamp;
    } else {
      _buildAndCache();
    }
  }

  void _buildAndCache() {
    final widget = this.widget.builder();
    final now = DateTime.now();
    
    _cache[_currentCacheKey!] = _CacheEntry(widget, now);
    
    setState(() {
      _cachedWidget = widget;
      _cacheTime = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedWidget != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < widget.cacheDuration) {
      return _cachedWidget!;
    }

    _buildAndCache();
    return _cachedWidget ?? const SizedBox.shrink();
  }

  @override
  void dispose() {
    // Limpiar caché viejo periódicamente
    _cleanupCache();
    super.dispose();
  }

  static void _cleanupCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => 
        now.difference(entry.timestamp) > const Duration(minutes: 10));
  }
}

class _CacheEntry {
  final Widget widget;
  final DateTime timestamp;

  _CacheEntry(this.widget, this.timestamp);
}

/// Widget de medición de performance
class PerformanceMeasureWidget extends StatefulWidget {
  final Widget child;
  final String? measurementName;
  final void Function(Duration buildTime)? onBuildTimeRecorded;

  const PerformanceMeasureWidget({
    super.key,
    required this.child,
    this.measurementName,
    this.onBuildTimeRecorded,
  });

  @override
  State<PerformanceMeasureWidget> createState() => _PerformanceMeasureWidgetState();
}

class _PerformanceMeasureWidgetState extends State<PerformanceMeasureWidget> {
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  @override
  Widget build(BuildContext context) {
    _stopwatch.stop();
    final buildTime = _stopwatch.elapsed;
    
    // Registrar tiempo de construcción si es significativo
    if (buildTime.inMilliseconds > 16) { // Más de un frame a 60fps
      widget.onBuildTimeRecorded?.call(buildTime);
      
      if (widget.measurementName != null) {
        debugPrint('Performance: ${widget.measurementName} took ${buildTime.inMilliseconds}ms to build');
      }
    }

    return widget.child;
  }
}

/// Mixin para widgets que necesitan optimizaciones de performance
mixin PerformanceOptimizedStatefulWidget<T extends StatefulWidget> on State<T> {
  /// Verificar si se debe construir el widget basado en performance
  bool shouldRebuild() {
    return !PerformanceService.lowMemoryMode;
  }

  /// Obtener duración de animación optimizada
  Duration getOptimizedDuration(Duration defaultDuration) {
    return PerformanceService.getAnimationDuration(defaultDuration);
  }

  /// Construir widget con medición de performance
  Widget buildWithPerformanceMeasure(Widget child, {String? measurementName}) {
    return PerformanceMeasureWidget(
      measurementName: measurementName ?? runtimeType.toString(),
      child: child,
    );
  }
}

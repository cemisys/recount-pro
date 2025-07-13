import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Botón con degradado indigo a teal por defecto
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final Widget? child;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.width,
    this.height,
    this.child,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  /// Constructor para botón con icono
  const GradientButton.icon({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.width,
    this.height,
    this.child,
    this.isLoading = false,
    this.fullWidth = false,
  });

  /// Constructor para botón de ancho completo
  const GradientButton.fullWidth({
    super.key,
    required this.text,
    this.onPressed,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.height = 50,
    this.child,
    this.isLoading = false,
    this.icon,
  }) : width = double.infinity, fullWidth = true;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = fullWidth ? double.infinity : width;
    final effectiveHeight = height ?? (fullWidth ? 50 : null);

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: Container(
        decoration: BoxDecoration(
          gradient: onPressed != null && !isLoading 
              ? AppTheme.primaryGradient 
              : LinearGradient(
                  colors: [
                    AppTheme.gradientStart.withValues(alpha: 0.5),
                    AppTheme.gradientEnd.withValues(alpha: 0.5),
                  ],
                ),
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          boxShadow: onPressed != null && !isLoading ? [
            BoxShadow(
              color: AppTheme.gradientStart.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed != null && !isLoading ? onPressed : null,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (child != null) {
      return child!;
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: textStyle ?? const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Text(
      text,
      style: textStyle ?? const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Botón secundario con borde degradado
class GradientOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final double? width;
  final double? height;
  final Widget? child;
  final bool isLoading;
  final IconData? icon;

  const GradientOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.width,
    this.height,
    this.child,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: onPressed != null && !isLoading 
                ? AppTheme.primaryColor 
                : AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed != null && !isLoading ? onPressed : null,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (child != null) {
      return child!;
    }

    final textColor = onPressed != null && !isLoading 
        ? AppTheme.primaryColor 
        : AppTheme.primaryColor.withValues(alpha: 0.5);

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: textStyle ?? TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Text(
      text,
      style: textStyle ?? TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}

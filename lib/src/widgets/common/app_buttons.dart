import 'package:flutter/material.dart';

/// Botón principal estandarizado de la aplicación Serum.
///
/// Diseñado con proporciones compactas para interfaces médicas y de gestión,
/// con soporte integrado para estado de carga [isLoading], iconografía,
/// y variante de alto contraste [isOnDark] para barras oscuras (ej. AppBar navy).
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isCompact;
  final bool isOnDark;
  final bool fullWidth;
  final String? tooltip;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isCompact = true,
    this.isOnDark = false,
    this.fullWidth = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveEnabled = onPressed != null && !isLoading;

    final Color backgroundColor = isOnDark
        ? (effectiveEnabled ? Colors.white : Colors.white.withValues(alpha: 0.4))
        : (effectiveEnabled
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.12));

    final Color foregroundColor = isOnDark
        ? const Color(0xFF0B1E36)
        : (effectiveEnabled
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface.withValues(alpha: 0.38));

    final double verticalPadding = isCompact ? 8.0 : 12.0;
    final double horizontalPadding = isCompact ? 14.0 : 20.0;
    final double height = isCompact ? 36.0 : 44.0;
    final double iconSize = isCompact ? 17.0 : 20.0;

    final Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    final button = Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      elevation: isOnDark ? 1 : 0,
      child: InkWell(
        onTap: effectiveEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        hoverColor: isOnDark
            ? Colors.white.withValues(alpha: 0.9)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          constraints: fullWidth
              ? const BoxConstraints(minWidth: double.infinity)
              : null,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Botón secundario estandarizado de la aplicación Serum.
///
/// Con diseño tipo Outlined/Tonal sutil, optimizado para acciones secundarias
/// ("Nuevo Paciente", "Nuevo Médico", "Cancelar"), con variante [isOnDark]
/// para barras superiores azul oscuro profundo.
class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isCompact;
  final bool isOnDark;
  final bool fullWidth;
  final String? tooltip;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isCompact = true,
    this.isOnDark = false,
    this.fullWidth = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveEnabled = onPressed != null && !isLoading;

    final Color borderColor = isOnDark
        ? (effectiveEnabled ? Colors.white.withValues(alpha: 0.35) : Colors.white24)
        : (effectiveEnabled
            ? theme.colorScheme.outlineVariant
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.5));

    final Color foregroundColor = isOnDark
        ? (effectiveEnabled ? Colors.white : Colors.white54)
        : (effectiveEnabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.38));

    final Color hoverColor = isOnDark
        ? Colors.white.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHigh;

    final double verticalPadding = isCompact ? 7.0 : 11.0;
    final double horizontalPadding = isCompact ? 12.0 : 16.0;
    final double height = isCompact ? 36.0 : 44.0;
    final double iconSize = isCompact ? 16.0 : 19.0;

    final Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: foregroundColor,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );

    final button = Material(
      color: isOnDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: effectiveEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        hoverColor: hoverColor,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          constraints: fullWidth
              ? const BoxConstraints(minWidth: double.infinity)
              : null,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Botón translúcido estilo glassmorphism para barras superiores (AppBar) y fondos oscuros.
///
/// Ofrece un acabado elegante con fondo semitransparente, borde fino y texto blanco.
/// Incluye soporte para resaltar acciones principales afirmativas mediante [isPrimary],
/// y animación de guardado/carga mediante [isLoading].
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final bool isCompact;
  final bool fullWidth;
  final String? tooltip;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = false,
    this.isCompact = true,
    this.fullWidth = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = onPressed != null && !isLoading;

    final Color backgroundColor = effectiveEnabled
        ? (isPrimary
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.08))
        : Colors.white.withValues(alpha: 0.04);

    final Color borderColor = effectiveEnabled
        ? (isPrimary
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.35))
        : Colors.white.withValues(alpha: 0.15);

    final Color foregroundColor = effectiveEnabled ? Colors.white : Colors.white54;
    final Color hoverColor = Colors.white.withValues(alpha: isPrimary ? 0.24 : 0.14);

    final double verticalPadding = isCompact ? 7.0 : 11.0;
    final double horizontalPadding = isCompact ? 13.0 : 18.0;
    final double height = isCompact ? 36.0 : 44.0;
    final double iconSize = isCompact ? 16.0 : 19.0;

    final Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 13 : 14,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
            color: foregroundColor,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );

    final button = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: isPrimary ? 1.2 : 1.0),
      ),
      child: InkWell(
        onTap: effectiveEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        hoverColor: hoverColor,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          constraints: fullWidth
              ? const BoxConstraints(minWidth: double.infinity)
              : null,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}


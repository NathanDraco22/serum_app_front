import 'dart:async';
import 'package:flutter/material.dart';

/// Diálogo reutilizable de confirmación para acciones críticas o destructivas
/// que exige un tiempo de espera preventivo (por defecto 5 segundos) antes de
/// permitir al usuario confirmar la acción.
class ConfirmDeleteDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? itemName;
  final String confirmLabel;
  final String cancelLabel;
  final int countdownSeconds;
  final IconData icon;
  final bool isDestructive;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    this.itemName,
    this.confirmLabel = 'Eliminar',
    this.cancelLabel = 'Cancelar',
    this.countdownSeconds = 5,
    this.icon = Icons.warning_amber_rounded,
    this.isDestructive = true,
  });

  /// Muestra el diálogo modal con temporizador regresivo.
  /// Retorna `true` si el usuario esperó los segundos y pulsó confirmar; `false` en caso contrario.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? itemName,
    String confirmLabel = 'Eliminar',
    String cancelLabel = 'Cancelar',
    int countdownSeconds = 5,
    IconData icon = Icons.warning_amber_rounded,
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmDeleteDialog(
        title: title,
        message: message,
        itemName: itemName,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        countdownSeconds: countdownSeconds,
        icon: icon,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    if (_remainingSeconds > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          _remainingSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCountingDown = _remainingSeconds > 0;
    final progress = widget.countdownSeconds > 0
        ? (widget.countdownSeconds - _remainingSeconds) / widget.countdownSeconds
        : 1.0;

    final primaryColor = widget.isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.itemName != null && widget.itemName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  widget.itemName!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
            if (widget.countdownSeconds > 0) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCountingDown
                        ? 'Espere $_remainingSeconds s para confirmar...'
                        : 'Acción habilitada',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCountingDown
                          ? theme.colorScheme.onSurfaceVariant
                          : primaryColor,
                      fontWeight: isCountingDown ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  if (isCountingDown)
                    Text(
                      '${widget.countdownSeconds - _remainingSeconds}/${widget.countdownSeconds}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: widget.isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            foregroundColor: widget.isDestructive
                ? theme.colorScheme.onError
                : theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isCountingDown
              ? null
              : () => Navigator.of(context).pop(true),
          icon: isCountingDown
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                )
              : const Icon(Icons.delete_forever_rounded, size: 18),
          label: Text(
            isCountingDown
                ? '${widget.confirmLabel} (${_remainingSeconds}s)'
                : widget.confirmLabel,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_shift_cubit/write_cash_shifts_cubit.dart';

class CashShiftOpenDialog extends StatefulWidget {
  const CashShiftOpenDialog({super.key});

  static Future<CashShiftInDb?> show(BuildContext context) {
    return showDialog<CashShiftInDb>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CashShiftOpenDialog(),
    );
  }

  @override
  State<CashShiftOpenDialog> createState() => _CashShiftOpenDialogState();
}

class _CashShiftOpenDialogState extends State<CashShiftOpenDialog> {
  final _formKey = GlobalKey<FormState>();
  final _initialCashController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _initialCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final sessionCubit = context.read<AppSessionCubit>();
    final user = sessionCubit.user;
    final branchId = sessionCubit.currentBranchId;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay sesión de usuario activa')),
      );
      return;
    }

    final doubleVal = double.tryParse(_initialCashController.text.trim()) ?? 0.0;
    final cents = (doubleVal * 100).round();

    final request = CreateCashShift(
      userId: user.id,
      branchId: branchId,
      initialBalance: cents,
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = true);

    final writeCubit = context.read<WriteCashShiftCubit>();
    final newShift = await writeCubit.openShift(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (newShift != null) {
      sessionCubit.setActiveShift(newShift);
      Navigator.of(context).pop(newShift);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Turno abierto correctamente con fondo de \$${(cents / 100.0).toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      final state = writeCubit.state;
      String errorMsg = 'Error al abrir el turno';
      if (state is WriteCashShiftError) {
        errorMsg = state.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<AppSessionCubit>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lock_open_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apertura de Turno de Caja',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ingresa el fondo inicial para comenzar la jornada',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Custodian / Branch badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withAlpha(120),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Custodio: ${session.user?.name ?? 'Usuario'} • ${session.currentBranchName}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Initial cash field
                TextFormField(
                  controller: _initialCashController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Fondo Inicial en Efectivo *',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    helperText: 'Efectivo con el que inicias operaciones en caja',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el fondo inicial';
                    }
                    final num = double.tryParse(value.trim());
                    if (num == null || num < 0) {
                      return 'Ingresa un monto válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Notes field
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notas / Observaciones (Opcional)',
                    hintText: 'Ej. Billetes de baja denominación, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(_isLoading ? 'Abriendo...' : 'Abrir Turno'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/lab_test_cubit/write_lab_tests_cubit.dart';

class LabTestQuickPriceDialog extends StatefulWidget {
  final LabTestInDb labTest;
  final String? branchId;

  const LabTestQuickPriceDialog({
    super.key,
    required this.labTest,
    this.branchId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required LabTestInDb labTest,
    String? branchId,
  }) {
    final writeCubit = context.read<WriteLabTestCubit>();
    final resolvedBranchId =
        branchId ?? context.read<AppSessionCubit>().currentBranchId;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => BlocProvider.value(
        value: writeCubit,
        child: LabTestQuickPriceDialog(
          labTest: labTest,
          branchId: resolvedBranchId,
        ),
      ),
    );
  }

  @override
  State<LabTestQuickPriceDialog> createState() =>
      _LabTestQuickPriceDialogState();
}

class _LabTestQuickPriceDialogState extends State<LabTestQuickPriceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _price2Controller;
  late bool _useChildTestsPriceSum;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final double inUnits = widget.labTest.salePrice / 100.0;
    _priceController = TextEditingController(
      text: inUnits > 0 ? inUnits.toStringAsFixed(2) : '0.00',
    );

    final double inUnits2 = widget.labTest.salePrice2 / 100.0;
    _price2Controller = TextEditingController(
      text: inUnits2 > 0 ? inUnits2.toStringAsFixed(2) : '0.00',
    );

    _useChildTestsPriceSum = widget.labTest.useChildTestsPriceSum;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _price2Controller.dispose();
    super.dispose();
  }

  int _parseCents(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    final val = double.tryParse(cleaned) ?? 0.0;
    return (val * 100).round();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final salePriceCents = _parseCents(_priceController.text);
    final salePrice2Cents = _parseCents(_price2Controller.text);

    // Si es un pack y se ingresa un precio manual, desactivamos la suma automática
    final bool resolvedUseChildSum = widget.labTest.isPack
        ? _useChildTestsPriceSum
        : true;

    setState(() => _isSaving = true);

    final updateModel = UpdateLabTest(
      branchId: widget.branchId,
      salePrice: salePriceCents,
      salePrice2: salePrice2Cents,
      useChildTestsPriceSum: widget.labTest.isPack ? resolvedUseChildSum : null,
    );

    final cubit = context.read<WriteLabTestCubit>();

    try {
      await cubit.update(widget.labTest.id, updateModel);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar precio: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPack = widget.labTest.isPack;

    return BlocListener<WriteLabTestCubit, WriteLabTestState>(
      listener: (context, state) {
        if (state is LabTestUpdated && mounted && _isSaving) {
          Navigator.of(context).pop(true);
        } else if (state is WriteLabTestError && mounted && _isSaving) {
          setState(() => _isSaving = false);
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.price_change_outlined,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modificar Precio de Análisis',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Actualización rápida en el catálogo de pruebas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta informativa del análisis
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isPack ? Icons.inventory_2 : Icons.science,
                              size: 16,
                              color: isPack
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.labTest.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (widget.labTest.code != null &&
                                widget.labTest.code!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Cód: ${widget.labTest.code}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.labTest.commercialCategory.isNotEmpty
                                    ? widget.labTest.commercialCategory
                                    : 'General',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (isPack)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Pack (${widget.labTest.childTestIds.length} análisis)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Si es Pack y tiene sumatoria automática, permitir alternar a tarifa fija
                  if (isPack) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue.shade800,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Modalidad de Precio del Perfil / Pack',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            dense: true,
                            title: const Text(
                              'Calcular precio sumando los análisis incluidos',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _useChildTestsPriceSum,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _useChildTestsPriceSum = val);
                              }
                            },
                          ),
                          if (_useChildTestsPriceSum)
                            Text(
                              'El precio se actualizará automáticamente a partir de la suma de sus pruebas hijas. Si deseas establecer una tarifa especial fija, desmarca esta casilla.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade800,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Campo Precio 1 (Regular)
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    autofocus: true,
                    enabled: !_isSaving &&
                        (!isPack || !_useChildTestsPriceSum),
                    decoration: InputDecoration(
                      labelText: isPack && _useChildTestsPriceSum
                          ? 'Precio 1 (Calculado por suma de hijos)'
                          : 'Precio 1 / Regular (\$)',
                      hintText: '0.00',
                      prefixText: '\$ ',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      helperText: 'Precio estándar de venta al público',
                    ),
                    validator: (val) {
                      if (isPack && _useChildTestsPriceSum) return null;
                      if (val == null || val.trim().isEmpty) {
                        return 'Ingrese un precio válido';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num < 0) {
                        return 'El precio no puede ser negativo';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Campo Precio 2 (Especial / Convenio)
                  TextFormField(
                    controller: _price2Controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Precio 2 / Convenio (\$ opcional)',
                      hintText: '0.00',
                      prefixText: '\$ ',
                      isDense: true,
                      border: OutlineInputBorder(),
                      helperText: 'Tarifa preferencial o de convenio',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return null;
                      final num = double.tryParse(val.trim());
                      if (num == null || num < 0) {
                        return 'El precio no puede ser negativo';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar Precio'),
          ),
        ],
      ),
    );
  }
}

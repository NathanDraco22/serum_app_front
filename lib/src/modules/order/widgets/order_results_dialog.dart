import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../tools/calculators/clinical_formulas_registry.dart';
import '../../../widgets/dialogs/viewers/clinical_order_viewer.dart';
import '../../../widgets/dialogs/viewers/patient_info_dialog.dart';
import '../controllers/order_results_mediator.dart';
import '../controllers/order_results_view_controller.dart';
import 'order_results_dialogs/order_results_header.dart';
import 'order_results_dialogs/order_results_summary_bar.dart';
import 'order_results_dialogs/order_results_section_header.dart';
import 'order_results_dialogs/parameter_card.dart';
import 'order_results_dialogs/order_results_footer.dart';

/// Diálogo principal orquestador para la captura, cálculo reactivo y guardado de resultados de laboratorio.
///
/// Siguiendo la arquitectura **ViewController + Mediator (OKF v0.2)**:
/// - Desacopla la lógica clínica, fórmulas y gestión de parámetros hacia [OrderResultsViewController].
/// - Expone el estado efímero mediante [OrderResultsMediator] eliminando el prop-drilling hacia subwidgets.
/// - Despacha la orden inmutable generada al [WriteOrderCubit] respetando la Regla de Oro.
class OrderResultsDialog extends StatefulWidget {
  final OrderInDb order;
  final bool? autoCalculateFormulas;

  const OrderResultsDialog({
    super.key,
    required this.order,
    this.autoCalculateFormulas,
  });

  @override
  State<OrderResultsDialog> createState() => _OrderResultsDialogState();
}

class _OrderResultsDialogState extends State<OrderResultsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final OrderResultsViewController _controller;
  late final List<FocusNode> _focusNodes;
  late final FocusNode _notesFocusNode;
  int? _activeFocusedIndex;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    bool shouldAutoCalculate = widget.autoCalculateFormulas ?? true;
    if (widget.autoCalculateFormulas == null) {
      try {
        final sessionState = context.read<AppSessionCubit>().state;
        final matchingBranch =
            sessionState.branches.where((b) => b.id == widget.order.branchId).firstOrNull ??
            sessionState.currentBranch;
        if (matchingBranch != null) {
          shouldAutoCalculate = matchingBranch.autoCalculateFormulas;
        }
      } catch (_) {
        shouldAutoCalculate = true;
      }
    }

    _controller = OrderResultsViewController(
      order: widget.order,
      autoCalculateFormulas: shouldAutoCalculate,
    );
    _notesFocusNode = FocusNode();

    _focusNodes = List.generate(_controller.results.length, (index) {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) {
          if (mounted && _activeFocusedIndex != index) {
            setState(() {
              _activeFocusedIndex = index;
            });
          }
          final r = _controller.results[index];
          final c = _controller.getController(r.labTestId);
          if (c != null && c.text.isNotEmpty) {
            c.selection = TextSelection(
              baseOffset: 0,
              extentOffset: c.text.length,
            );
          }
        }
      });
      return node;
    });

    _notesFocusNode.addListener(() {
      if (_notesFocusNode.hasFocus && mounted && _activeFocusedIndex != -1) {
        setState(() {
          _activeFocusedIndex = -1;
        });
      }
    });

    if (_focusNodes.isNotEmpty) {
      _activeFocusedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNodes.isNotEmpty) {
          _focusNodes.first.requestFocus();
        }
      });
    }
  }

  void _onFieldSubmitted(int index) {
    if (index + 1 < _focusNodes.length) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _notesFocusNode.requestFocus();
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Descartar cambios'),
        content: const Text(
          'Hay resultados o notas sin guardar. Si sales ahora, se perderán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar y salir'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _requestClose() async {
    if (_controller.isSubmitting) return;

    if (_controller.hasUnsavedChanges) {
      final discard = await _confirmDiscard();
      if (!mounted || !discard) return;
    }

    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _notesFocusNode.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    // Validación de Negocio Estricta: Si se ingresó el diferencial y el cálculo automático está activo, debe sumar exactamente 100%
    if (_controller.autoCalculateFormulas &&
        _controller.hasDifferentialStarted &&
        !_controller.isDifferentialValid) {
      final sum = _controller.differentialSum;
      final sumText = sum != null ? ClinicalFormulasRegistry.formatClinicalValue(sum, 1) : '0.0';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El conteo diferencial debe sumar exactamente 100% (actualmente suma $sumText%). Corrija los valores antes de guardar.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    _controller.isSubmitting = true;

    try {
      final updateOrder = _controller.generateUpdateOrder();
      final writeCubit = context.read<WriteOrderCubit>();
      await writeCubit.update(widget.order.id, updateOrder);

      if (!mounted) return;

      final state = writeCubit.state;
      if (state is OrderUpdated) {
        setState(() => _allowPop = true);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      } else if (state is WriteOrderError) {
        _controller.isSubmitting = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar resultados: ${state.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        _controller.isSubmitting = false;
      }
    } catch (e) {
      if (mounted) {
        _controller.isSubmitting = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const isReadOnly = false;

    return OrderResultsMediator(
      viewController: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          OrderTestResult? activeResult;
          String? activeStudy;
          if (_activeFocusedIndex != null &&
              _activeFocusedIndex! >= 0 &&
              _activeFocusedIndex! < _controller.results.length) {
            activeResult = _controller.results[_activeFocusedIndex!];
            activeStudy = _controller.getStudyName(activeResult);
          }

          return PopScope(
            canPop: _allowPop || _controller.isSubmitting,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop || _controller.isSubmitting) return;
              if (!_controller.hasUnsavedChanges) {
                setState(() => _allowPop = true);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
                return;
              }
              final discard = await _confirmDiscard();
              if (!mounted || !discard) return;
              setState(() => _allowPop = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            },
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 680,
                  maxHeight: 680,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Cabecera Visual con Icono y Contexto
                    OrderResultsHeader(
                      onShowPatientInfo: () => showOrderPatientInfoDialog(context, widget.order),
                      onClose: _requestClose,
                    ),

                    // 2. Barra de Resumen / Métricas Compacta
                    const OrderResultsSummaryBar(),
                    const Divider(height: 1),

                    // 3. Lista de Parámetros con Tarjetas Claras y Observaciones
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _controller.results.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == _controller.results.length) {
                              return _buildNotesSection(theme, isReadOnly);
                            }

                            final r = _controller.results[index];
                            final currentStudy = _controller.getStudyName(r);
                            final prevStudy = index > 0
                                ? _controller.getStudyName(_controller.results[index - 1])
                                : null;
                            final isNewStudy =
                                index > 0 &&
                                prevStudy != null &&
                                currentStudy.toUpperCase() != prevStudy.toUpperCase();

                            final isStudyActive =
                                activeStudy != null &&
                                activeStudy.toUpperCase() == currentStudy.toUpperCase();

                            final card = ParameterCard(
                              key: ValueKey(r.labTestId),
                              result: r,
                              focusNode: _focusNodes[index],
                              isLast: false,
                              onFieldSubmitted: () => _onFieldSubmitted(index),
                            );

                            // El separador visual de perfil solo se muestra cuando la orden
                            // contiene múltiples perfiles/estudios clínicos y comienza un nuevo bloque.
                            if (!_controller.hasMultipleStudies || !isNewStudy) {
                              return card;
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OrderResultsSectionHeader(
                                  studyTitle: currentStudy,
                                  clinicalArea: r.medicalClassification,
                                  completedCount: _controller.getStudyCompletedCount(currentStudy),
                                  totalCount: _controller.getStudyTotalCount(currentStudy),
                                  isCurrentActive: isStudyActive,
                                ),
                                const SizedBox(height: 6),
                                card,
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // 4. Footer de Acciones
                    OrderResultsFooter(
                      isReadOnly: isReadOnly,
                      onViewReport: () {
                        showClinicalOrderViewerDialog(
                          context,
                          _controller.buildPreviewOrder(),
                        );
                      },
                      onCancel: _requestClose,
                      onSubmit: _submit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme, bool isReadOnly) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Descripción / Observaciones del Bioanalista',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (isReadOnly) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Solo Lectura',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _controller.notesController,
            focusNode: _notesFocusNode,
            readOnly: isReadOnly,
            maxLines: 3,
            minLines: 2,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: isReadOnly
                  ? 'Sin descripción ni observaciones registradas'
                  : 'Ingrese notas diagnósticas, descripción clínica, incidencias de la muestra (ej. hemólisis, lipemia), o comentarios clínicos...',
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: isReadOnly
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : theme.colorScheme.surface,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

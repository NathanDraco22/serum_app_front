import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import 'patient_history_empty_state.dart';
import 'patient_history_order_card.dart';

/// Listado de órdenes del paciente que alterna entre el estado vacío y las tarjetas de orden.
class PatientHistoryOrdersList extends StatelessWidget {
  final List<OrderInDb> orders;
  final PatientInDb? patient;
  final bool isComparisonMode;
  final Set<String> selectedOrderIdsForComparison;
  final bool hasFiltersApplied;
  final ValueChanged<String> onToggleComparison;
  final ValueChanged<OrderInDb> onOpenReceipts;
  final ValueChanged<OrderInDb> onOpenInvoice;
  final ValueChanged<OrderInDb> onOpenResults;
  final VoidCallback onClearFilters;

  const PatientHistoryOrdersList({
    super.key,
    required this.orders,
    this.patient,
    required this.isComparisonMode,
    required this.selectedOrderIdsForComparison,
    required this.hasFiltersApplied,
    required this.onToggleComparison,
    required this.onOpenReceipts,
    required this.onOpenInvoice,
    required this.onOpenResults,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return PatientHistoryEmptyState(
        hasFiltersApplied: hasFiltersApplied,
        onClearFilters: onClearFilters,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return PatientHistoryOrderCard(
          order: order,
          patient: patient,
          isComparisonMode: isComparisonMode,
          isSelectedForComparison: selectedOrderIdsForComparison.contains(order.id),
          onToggleComparison: onToggleComparison,
          onOpenReceipts: () => onOpenReceipts(order),
          onOpenInvoice: () => onOpenInvoice(order),
          onOpenResults: () => onOpenResults(order),
        );
      },
    );
  }
}

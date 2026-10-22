import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../order/widgets/order_receipts_history_dialog.dart';
import '../../../widgets/dialogs/viewers/clinical_comparison_viewer_dialog.dart';
import '../../../widgets/dialogs/viewers/clinical_order_viewer.dart';
import '../../../widgets/dialogs/viewers/order_invoice_viewer.dart';
import '../widgets/patient_orders_history/patient_history_bottom_bar.dart';
import '../widgets/patient_orders_history/patient_history_filters_bar.dart';
import '../widgets/patient_orders_history/patient_history_header.dart';
import '../widgets/patient_orders_history/patient_history_helpers.dart';
import '../widgets/patient_orders_history/patient_history_orders_list.dart';

/// Pantalla completa para visualizar el expediente e historial clínico de órdenes
/// asociadas a un paciente, con soporte para la comparación analítica de exámenes.
class PatientOrdersHistoryScreen extends StatefulWidget {
  final String patientId;
  final PatientInDb? patient;

  const PatientOrdersHistoryScreen({
    super.key,
    required this.patientId,
    this.patient,
  });

  /// Permite invocar la pantalla completa desde cualquier lugar de la aplicación.
  static Future<void> show(
    BuildContext context, {
    required String patientId,
    PatientInDb? patient,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientOrdersHistoryScreen(
          patientId: patientId,
          patient: patient,
        ),
      ),
    );
  }

  @override
  State<PatientOrdersHistoryScreen> createState() =>
      _PatientOrdersHistoryScreenState();
}

class _PatientOrdersHistoryScreenState
    extends State<PatientOrdersHistoryScreen> {
  PatientInDb? _patient;
  List<OrderInDb> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  bool _comparisonMode = false;
  final Set<String> _selectedOrderIdsForComparison = <String>{};

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final patientsRepo = context.read<PatientsRepository>();
    final ordersRepo = context.read<OrdersRepository>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _patient ??= await patientsRepo.getPatientById(widget.patientId);
      final orders = await ordersRepo.getOrdersByPatientId(
        widget.patientId,
        allBranches: true,
      );
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<OrderInDb> get _filteredOrders {
    return _orders.where((order) {
      if (_selectedStatusFilter != 'ALL' &&
          order.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesId = order.id.toLowerCase().contains(query);
        final matchesDoctor = order.doctorInfo?.name.toLowerCase().contains(query) ?? false;
        final matchesItems = order.items.any((i) => i.name.toLowerCase().contains(query));
        return matchesId || matchesDoctor || matchesItems;
      }
      return true;
    }).toList();
  }

  int get _totalBilled => _orders.fold<int>(
      0, (sum, o) => sum + (o.totalPrice > 0 ? o.totalPrice : o.salePriceApplied));

  int get _totalPendingBalance => _orders.fold<int>(0, (sum, o) {
        final total = o.totalPrice > 0 ? o.totalPrice : o.salePriceApplied;
        final pending = total - o.paidAmount;
        return sum + (pending > 0 ? pending : 0);
      });

  int get _completedOrdersCount =>
      _orders.where((o) => o.status == 'completed' || o.status == 'published').length;

  List<OrderInDb> get _biometryOrders =>
      _orders.where(PatientHistoryHelpers.isBiometryOrder).toList();

  void _toggleOrderComparison(String orderId) {
    setState(() {
      if (_selectedOrderIdsForComparison.contains(orderId)) {
        _selectedOrderIdsForComparison.remove(orderId);
      } else {
        if (_selectedOrderIdsForComparison.length >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por ahora puedes comparar un máximo de 2 órdenes simultáneamente.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedOrderIdsForComparison.add(orderId);
      }
    });
  }

  PatientInfo? _resolvePatientInfo(OrderInDb order) {
    return order.patientInfo ??
        (_patient != null
            ? PatientInfo(
                name: _patient!.name,
                dateOfBirth: _patient!.dateOfBirth,
                gender: _patient!.gender,
                phone: _patient!.phone,
                address: _patient!.address ?? '',
                cardId: _patient!.cardId,
                email: _patient!.email,
              )
            : null);
  }

  void _openComparisonDialog(OrderInDb order1, OrderInDb order2) {
    if (order1.results.isEmpty && order2.results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ninguna de las órdenes seleccionadas tiene resultados registrados para comparar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showClinicalComparisonViewerDialog(
      context,
      order1: order1,
      order2: order2,
      patientInfo: order2.patientInfo ?? order1.patientInfo ?? _resolvePatientInfo(order2),
      doctorInfo: order2.doctorInfo ?? order1.doctorInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final patientName = _patient?.name ?? 'Paciente #${widget.patientId}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Órdenes Clínicas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              patientName,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (_orders.length >= 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                selected: _comparisonMode,
                avatar: Icon(
                  Icons.compare_arrows_rounded,
                  size: 18,
                  color: _comparisonMode ? colorScheme.onPrimary : colorScheme.primary,
                ),
                label: Text(
                  _comparisonMode
                      ? 'Comparando (${_selectedOrderIdsForComparison.length}/2)'
                      : 'Modo Comparar',
                  style: TextStyle(
                    color: _comparisonMode ? colorScheme.onPrimary : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
                onSelected: (val) {
                  setState(() {
                    _comparisonMode = val;
                    if (!val) _selectedOrderIdsForComparison.clear();
                  });
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar historial',
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(theme, colorScheme),
      bottomNavigationBar: _comparisonMode && _selectedOrderIdsForComparison.isNotEmpty
          ? PatientHistoryBottomBar(
              selectedCount: _selectedOrderIdsForComparison.length,
              onClear: () => setState(() => _selectedOrderIdsForComparison.clear()),
              onCompare: _selectedOrderIdsForComparison.length == 2
                  ? () {
                      final selected = _orders
                          .where((o) => _selectedOrderIdsForComparison.contains(o.id))
                          .toList();
                      if (selected.length == 2) {
                        _openComparisonDialog(selected[0], selected[1]);
                      }
                    }
                  : null,
            )
          : null,
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando expediente clínico del paciente...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Ocurrió un error al cargar las órdenes',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        PatientHistoryHeader(
          patient: _patient,
          patientId: widget.patientId,
          totalOrdersCount: _orders.length,
          completedOrdersCount: _completedOrdersCount,
          totalBilled: _totalBilled,
          totalPendingBalance: _totalPendingBalance,
          biometryOrders: _biometryOrders,
          onCompareBiometries: () {
            if (_biometryOrders.length >= 2) {
              _openComparisonDialog(_biometryOrders[0], _biometryOrders[1]);
            }
          },
        ),
        PatientHistoryFiltersBar(
          searchController: _searchController,
          searchQuery: _searchQuery,
          selectedStatus: _selectedStatusFilter,
          onSearchChanged: (val) => setState(() => _searchQuery = val),
          onStatusFilterChanged: (status) => setState(() => _selectedStatusFilter = status),
          onClearSearch: () => setState(() {
            _searchController.clear();
            _searchQuery = '';
          }),
        ),
        Expanded(
          child: PatientHistoryOrdersList(
            orders: _filteredOrders,
            patient: _patient,
            isComparisonMode: _comparisonMode,
            selectedOrderIdsForComparison: _selectedOrderIdsForComparison,
            hasFiltersApplied: _searchQuery.isNotEmpty || _selectedStatusFilter != 'ALL',
            onToggleComparison: _toggleOrderComparison,
            onOpenReceipts: (order) => OrderReceiptsHistoryDialog.show(context, order),
            onOpenInvoice: (order) => showOrderInvoiceViewerDialog(
              context,
              order,
              patientInfo: _resolvePatientInfo(order),
            ),
            onOpenResults: (order) => showClinicalOrderViewerDialog(
              context,
              order,
              patientInfo: _resolvePatientInfo(order),
            ),
            onClearFilters: () => setState(() {
              _searchController.clear();
              _searchQuery = '';
              _selectedStatusFilter = 'ALL';
            }),
          ),
        ),
      ],
    );
  }
}

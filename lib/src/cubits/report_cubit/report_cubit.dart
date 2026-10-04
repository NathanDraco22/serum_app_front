import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportsRepository reportsRepository;

  ReportCubit({
    required this.reportsRepository,
    String? initialBranchId,
  }) : super(_createInitialState(initialBranchId));

  static ReportState _createInitialState(String? initialBranchId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return ReportState(
      startDate: startOfMonth,
      endDate: endOfDay,
      branchId: initialBranchId,
    );
  }

  int get _startMs => state.startDate.millisecondsSinceEpoch;
  int get _endMs => state.endDate.millisecondsSinceEpoch;

  Future<void> changeTab(ReportTab tab) async {
    if (state.activeTab == tab && state.status == ReportStatus.loaded) return;
    emit(state.copyWith(activeTab: tab));
    await loadActiveReport();
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    final normalizedStart =
        DateTime(start.year, start.month, start.day, 0, 0, 0);
    final normalizedEnd =
        DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    emit(state.copyWith(
      startDate: normalizedStart,
      endDate: normalizedEnd,
    ));
    await loadActiveReport();
  }

  Future<void> setBranchId(String? branchId) async {
    emit(state.copyWith(
      branchId: branchId,
      clearBranchId: branchId == null,
    ));
    await loadActiveReport();
  }

  Future<void> setLabTestsSource(String source) async {
    if (state.labTestsSource == source) return;
    emit(state.copyWith(labTestsSource: source));
    if (state.activeTab == ReportTab.labTestsVolume) {
      await _loadLabTestsVolume();
    }
  }

  Future<void> setOnlyDiscrepancies(bool onlyDiscrepancies) async {
    if (state.onlyDiscrepancies == onlyDiscrepancies) return;
    emit(state.copyWith(onlyDiscrepancies: onlyDiscrepancies));
    if (state.activeTab == ReportTab.shiftsAudit) {
      await _loadShiftsAudit();
    }
  }

  Future<void> refresh() async {
    await loadActiveReport();
  }

  Future<void> loadActiveReport() async {
    switch (state.activeTab) {
      case ReportTab.financial:
        await _loadFinancial();
        break;
      case ReportTab.topDoctors:
        await _loadTopDoctors();
        break;
      case ReportTab.labTestsVolume:
        await _loadLabTestsVolume();
        break;
      case ReportTab.pendingBalances:
        await _loadPendingBalances();
        break;
      case ReportTab.shiftsAudit:
        await _loadShiftsAudit();
        break;
    }
  }

  Future<void> _loadFinancial() async {
    emit(state.copyWith(status: ReportStatus.loading, clearError: true));
    try {
      final res = await reportsRepository.getFinancialReport(
        startDate: _startMs,
        endDate: _endMs,
        branchId: state.branchId,
      );
      emit(state.copyWith(
        status: ReportStatus.loaded,
        financialReport: res,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.error,
        errorMessage: 'Error al cargar reporte financiero: $e',
      ));
    }
  }

  Future<void> _loadTopDoctors() async {
    emit(state.copyWith(status: ReportStatus.loading, clearError: true));
    try {
      final res = await reportsRepository.getTopDoctorsReport(
        startDate: _startMs,
        endDate: _endMs,
        branchId: state.branchId,
        limit: 10,
      );
      emit(state.copyWith(
        status: ReportStatus.loaded,
        topDoctorsReport: res,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.error,
        errorMessage: 'Error al cargar top médicos: $e',
      ));
    }
  }

  Future<void> _loadLabTestsVolume() async {
    emit(state.copyWith(status: ReportStatus.loading, clearError: true));
    try {
      final res = await reportsRepository.getLabTestsVolumeReport(
        startDate: _startMs,
        endDate: _endMs,
        branchId: state.branchId,
        source: state.labTestsSource,
        limit: 10,
      );
      emit(state.copyWith(
        status: ReportStatus.loaded,
        labTestsVolumeReport: res,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.error,
        errorMessage: 'Error al cargar volumen de análisis: $e',
      ));
    }
  }

  Future<void> _loadPendingBalances() async {
    emit(state.copyWith(status: ReportStatus.loading, clearError: true));
    try {
      final res = await reportsRepository.getPendingBalancesReport(
        startDate: _startMs,
        endDate: _endMs,
        branchId: state.branchId,
      );
      emit(state.copyWith(
        status: ReportStatus.loaded,
        pendingBalancesReport: res,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.error,
        errorMessage: 'Error al cargar cuentas por cobrar: $e',
      ));
    }
  }

  Future<void> _loadShiftsAudit() async {
    emit(state.copyWith(status: ReportStatus.loading, clearError: true));
    try {
      final res = await reportsRepository.getShiftsAuditReport(
        startDate: _startMs,
        endDate: _endMs,
        branchId: state.branchId,
        onlyDiscrepancies: state.onlyDiscrepancies,
      );
      emit(state.copyWith(
        status: ReportStatus.loaded,
        shiftsAuditReport: res,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.error,
        errorMessage: 'Error al cargar auditoría de turnos: $e',
      ));
    }
  }
}

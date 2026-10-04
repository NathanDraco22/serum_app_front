import 'package:serum_business/serum_business.dart';

enum ReportTab {
  financial,
  topDoctors,
  labTestsVolume,
  pendingBalances,
  shiftsAudit,
}

enum ReportStatus {
  initial,
  loading,
  loaded,
  error,
}

class ReportState {
  final ReportStatus status;
  final ReportTab activeTab;
  final DateTime startDate;
  final DateTime endDate;
  final String? branchId;
  final String labTestsSource;
  final bool onlyDiscrepancies;
  final String? errorMessage;

  final FinancialReportResponse? financialReport;
  final TopDoctorsReportResponse? topDoctorsReport;
  final LabTestsVolumeReportResponse? labTestsVolumeReport;
  final PendingBalancesReportResponse? pendingBalancesReport;
  final ShiftsAuditReportResponse? shiftsAuditReport;

  const ReportState({
    this.status = ReportStatus.initial,
    this.activeTab = ReportTab.financial,
    required this.startDate,
    required this.endDate,
    this.branchId,
    this.labTestsSource = 'orders',
    this.onlyDiscrepancies = false,
    this.errorMessage,
    this.financialReport,
    this.topDoctorsReport,
    this.labTestsVolumeReport,
    this.pendingBalancesReport,
    this.shiftsAuditReport,
  });

  bool get isLoading => status == ReportStatus.loading;

  ReportState copyWith({
    ReportStatus? status,
    ReportTab? activeTab,
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    bool clearBranchId = false,
    String? labTestsSource,
    bool? onlyDiscrepancies,
    String? errorMessage,
    bool clearError = false,
    FinancialReportResponse? financialReport,
    TopDoctorsReportResponse? topDoctorsReport,
    LabTestsVolumeReportResponse? labTestsVolumeReport,
    PendingBalancesReportResponse? pendingBalancesReport,
    ShiftsAuditReportResponse? shiftsAuditReport,
  }) {
    return ReportState(
      status: status ?? this.status,
      activeTab: activeTab ?? this.activeTab,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      branchId: clearBranchId ? null : (branchId ?? this.branchId),
      labTestsSource: labTestsSource ?? this.labTestsSource,
      onlyDiscrepancies: onlyDiscrepancies ?? this.onlyDiscrepancies,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      financialReport: financialReport ?? this.financialReport,
      topDoctorsReport: topDoctorsReport ?? this.topDoctorsReport,
      labTestsVolumeReport: labTestsVolumeReport ?? this.labTestsVolumeReport,
      pendingBalancesReport:
          pendingBalancesReport ?? this.pendingBalancesReport,
      shiftsAuditReport: shiftsAuditReport ?? this.shiftsAuditReport,
    );
  }
}

import '../models/report_model/report_models.dart';
import '../../data/reports_data_source.dart';

class ReportsRepository {
  final ReportsDataSource reportsDataSource;

  ReportsRepository(this.reportsDataSource);

  Future<FinancialReportResponse> getFinancialReport({
    required int startDate,
    required int endDate,
    String? branchId,
  }) async {
    final result = await reportsDataSource.getFinancialReport(
      startDate: startDate,
      endDate: endDate,
      branchId: branchId,
    );
    return FinancialReportResponse.fromMap(result);
  }

  Future<TopDoctorsReportResponse> getTopDoctorsReport({
    required int startDate,
    required int endDate,
    String? branchId,
    int limit = 10,
  }) async {
    final result = await reportsDataSource.getTopDoctorsReport(
      startDate: startDate,
      endDate: endDate,
      branchId: branchId,
      limit: limit,
    );
    return TopDoctorsReportResponse.fromMap(result);
  }

  Future<LabTestsVolumeReportResponse> getLabTestsVolumeReport({
    required int startDate,
    required int endDate,
    String? branchId,
    String source = 'orders',
    int limit = 10,
  }) async {
    final result = await reportsDataSource.getLabTestsVolumeReport(
      startDate: startDate,
      endDate: endDate,
      branchId: branchId,
      source: source,
      limit: limit,
    );
    return LabTestsVolumeReportResponse.fromMap(result);
  }

  Future<PendingBalancesReportResponse> getPendingBalancesReport({
    required int startDate,
    required int endDate,
    String? branchId,
  }) async {
    final result = await reportsDataSource.getPendingBalancesReport(
      startDate: startDate,
      endDate: endDate,
      branchId: branchId,
    );
    return PendingBalancesReportResponse.fromMap(result);
  }

  Future<ShiftsAuditReportResponse> getShiftsAuditReport({
    required int startDate,
    required int endDate,
    String? branchId,
    bool onlyDiscrepancies = false,
  }) async {
    final result = await reportsDataSource.getShiftsAuditReport(
      startDate: startDate,
      endDate: endDate,
      branchId: branchId,
      onlyDiscrepancies: onlyDiscrepancies,
    );
    return ShiftsAuditReportResponse.fromMap(result);
  }
}

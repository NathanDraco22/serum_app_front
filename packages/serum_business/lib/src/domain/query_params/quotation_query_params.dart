class QuotationQueryParams {
  final String? branchId;
  final String? patientId;
  final String? doctorId;
  final String? status;
  final int? startDate;
  final int? endDate;
  final int offset;
  final int limit;

  QuotationQueryParams({
    this.branchId,
    this.patientId,
    this.doctorId,
    this.status,
    this.startDate,
    this.endDate,
    this.offset = 0,
    this.limit = 50,
  });

  factory QuotationQueryParams.last30Days({
    String? branchId,
    String? patientId,
    String? doctorId,
    String? status,
    int offset = 0,
    int limit = 50,
  }) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return QuotationQueryParams(
      branchId: branchId,
      patientId: patientId,
      doctorId: doctorId,
      status: status,
      startDate: thirtyDaysAgo.millisecondsSinceEpoch,
      endDate: now.millisecondsSinceEpoch,
      offset: offset,
      limit: limit,
    );
  }

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    if (branchId != null) map['branchId'] = branchId!;
    if (patientId != null) map['patientId'] = patientId!;
    if (doctorId != null) map['doctorId'] = doctorId!;
    if (status != null) map['status'] = status!;
    if (startDate != null) map['startDate'] = startDate.toString();
    if (endDate != null) map['endDate'] = endDate.toString();
    map['offset'] = offset.toString();
    map['limit'] = limit.toString();
    return map;
  }
}

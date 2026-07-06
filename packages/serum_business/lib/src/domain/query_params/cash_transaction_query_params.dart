class CashTransactionQueryParams {
  final String? registerId;
  final String? flowType;
  final String? subType;
  final String? paymentMethod;
  final int? startDate;
  final int? endDate;
  final int offset;
  final int limit;

  CashTransactionQueryParams({
    this.registerId,
    this.flowType,
    this.subType,
    this.paymentMethod,
    this.startDate,
    this.endDate,
    this.offset = 0,
    this.limit = 50,
  });

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    if (registerId != null) map['registerId'] = registerId!;
    if (flowType != null) map['flowType'] = flowType!;
    if (subType != null) map['subType'] = subType!;
    if (paymentMethod != null) map['paymentMethod'] = paymentMethod!;
    if (startDate != null) map['startDate'] = startDate.toString();
    if (endDate != null) map['endDate'] = endDate.toString();
    map['offset'] = offset.toString();
    map['limit'] = limit.toString();
    return map;
  }
}

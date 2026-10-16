class ReceiptQueryParams {
  final String? orderId;
  final String? branchId;
  final String? shiftId;
  final String? registerId;
  final String? paymentMethod;
  final int? startDate;
  final int? endDate;
  final int offset;
  final int limit;

  ReceiptQueryParams({
    this.orderId,
    this.branchId,
    this.shiftId,
    this.registerId,
    this.paymentMethod,
    this.startDate,
    this.endDate,
    this.offset = 0,
    this.limit = 50,
  });

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    if (orderId != null) map['orderId'] = orderId!;
    if (branchId != null) map['branchId'] = branchId!;
    if (shiftId != null) map['shiftId'] = shiftId!;
    if (registerId != null) map['registerId'] = registerId!;
    if (paymentMethod != null) map['paymentMethod'] = paymentMethod!;
    if (startDate != null) map['startDate'] = startDate.toString();
    if (endDate != null) map['endDate'] = endDate.toString();
    map['offset'] = offset.toString();
    map['limit'] = limit.toString();
    return map;
  }
}

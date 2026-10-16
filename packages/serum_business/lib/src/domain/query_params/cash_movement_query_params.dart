class CashMovementQueryParams {
  final String? shiftId;
  final String? branchId;
  final String? movementType;
  final String? paymentMethod;
  final int? startDate;
  final int? endDate;
  final int offset;
  final int limit;

  CashMovementQueryParams({
    this.shiftId,
    this.branchId,
    this.movementType,
    this.paymentMethod,
    this.startDate,
    this.endDate,
    this.offset = 0,
    this.limit = 50,
  });

  Map<String, String> toQueryParameters() {
    final map = <String, String>{};
    if (shiftId != null) map['shiftId'] = shiftId!;
    if (branchId != null) map['branchId'] = branchId!;
    if (movementType != null) map['movementType'] = movementType!;
    if (paymentMethod != null) map['paymentMethod'] = paymentMethod!;
    if (startDate != null) map['startDate'] = startDate.toString();
    if (endDate != null) map['endDate'] = endDate.toString();
    map['offset'] = offset.toString();
    map['limit'] = limit.toString();
    return map;
  }
}

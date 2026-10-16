import '../shared/user_info.dart';
import '../../../tools/number_formatter.dart';

class BaseReceipt {
  final String receiptNumber;
  final String orderId;
  final String? orderNumber;
  final String branchId;
  final String? shiftId;
  final String? registerId;
  final int amount;
  final String paymentMethod;
  final String concept;
  final UserInfo performedBy;
  final String? patientName;

  BaseReceipt({
    required this.receiptNumber,
    required this.orderId,
    this.orderNumber,
    required this.branchId,
    this.shiftId,
    this.registerId,
    required this.amount,
    this.paymentMethod = 'cash',
    this.concept = 'Pago / Abono de orden',
    required this.performedBy,
    this.patientName,
  });
}

class CreateReceipt {
  final String? receiptNumber;
  final String orderId;
  final String? orderNumber;
  final String branchId;
  final String? shiftId;
  final String? registerId;
  final int amount;
  final String paymentMethod;
  final String concept;
  final UserInfo performedBy;
  final String? patientName;

  CreateReceipt({
    this.receiptNumber,
    required this.orderId,
    this.orderNumber,
    required this.branchId,
    this.shiftId,
    this.registerId,
    required this.amount,
    this.paymentMethod = 'cash',
    this.concept = 'Pago / Abono de orden',
    required this.performedBy,
    this.patientName,
  });

  Map<String, dynamic> toJson() {
    return {
      if (receiptNumber != null) 'receiptNumber': receiptNumber,
      'orderId': orderId,
      if (orderNumber != null) 'orderNumber': orderNumber,
      'branchId': branchId,
      if (shiftId != null) 'shiftId': shiftId,
      if (registerId != null) 'registerId': registerId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'concept': concept,
      'performedBy': performedBy.toJson(),
      if (patientName != null) 'patientName': patientName,
    };
  }
}

class UpdateReceipt {
  final String? concept;
  final String? patientName;

  UpdateReceipt({
    this.concept,
    this.patientName,
  });

  Map<String, dynamic> toJson() {
    return {
      if (concept != null) 'concept': concept,
      if (patientName != null) 'patientName': patientName,
    };
  }
}

class ReceiptInDb extends BaseReceipt {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  ReceiptInDb({
    required this.id,
    required super.receiptNumber,
    required super.orderId,
    super.orderNumber,
    required super.branchId,
    super.shiftId,
    super.registerId,
    required super.amount,
    super.paymentMethod = 'cash',
    super.concept = 'Pago / Abono de orden',
    required super.performedBy,
    super.patientName,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  double get amountDouble => NumberFormatter.convertFromCentsToDouble(amount);
  String get formattedAmount => NumberFormatter.convertToMoneyLike(amount);

  String get paymentMethodLabel {
    switch (paymentMethod.toLowerCase()) {
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'cash':
      default:
        return 'Efectivo';
    }
  }

  String get formattedDate {
    if (createdAt <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  factory ReceiptInDb.fromJson(Map<String, dynamic> json) {
    return ReceiptInDb(
      id: json['id'] as String? ?? json['receiptNumber'] as String? ?? '',
      receiptNumber:
          json['receiptNumber'] as String? ?? json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String?,
      branchId: json['branchId'] as String? ?? '',
      shiftId: json['shiftId'] as String?,
      registerId: json['registerId'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      concept: json['concept'] as String? ?? 'Pago / Abono de orden',
      performedBy: json['performedBy'] != null
          ? UserInfo.fromJson(json['performedBy'] as Map<String, dynamic>)
          : UserInfo(id: '', name: 'Operador'),
      patientName: json['patientName'] as String?,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

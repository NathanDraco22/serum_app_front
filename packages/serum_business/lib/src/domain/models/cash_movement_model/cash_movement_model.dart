import '../shared/user_info.dart';
import '../../../tools/number_formatter.dart';

class BaseCashMovement {
  final String shiftId;
  final String branchId;
  final String movementType;
  final String paymentMethod;
  final int amount;
  final String concept;
  final UserInfo performedBy;
  final int? resultingBalance;
  final String? registerId;

  BaseCashMovement({
    required this.shiftId,
    required this.branchId,
    required this.movementType,
    this.paymentMethod = 'cash',
    required this.amount,
    required this.concept,
    required this.performedBy,
    this.resultingBalance,
    this.registerId,
  });
}

class CreateCashMovement {
  final String shiftId;
  final String branchId;
  final String movementType;
  final String paymentMethod;
  final int amount;
  final String concept;
  final UserInfo performedBy;
  final String? registerId;

  CreateCashMovement({
    required this.shiftId,
    required this.branchId,
    required this.movementType,
    this.paymentMethod = 'cash',
    required this.amount,
    required this.concept,
    required this.performedBy,
    this.registerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'shiftId': shiftId,
      'branchId': branchId,
      'movementType': movementType,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'concept': concept,
      'performedBy': performedBy.toJson(),
      if (registerId != null) 'registerId': registerId,
    };
  }
}

class UpdateCashMovement {
  final String? concept;

  UpdateCashMovement({
    this.concept,
  });

  Map<String, dynamic> toJson() {
    return {
      if (concept != null) 'concept': concept,
    };
  }
}

class CashMovementInDb extends BaseCashMovement {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  CashMovementInDb({
    required this.id,
    required super.shiftId,
    required super.branchId,
    required super.movementType,
    super.paymentMethod = 'cash',
    required super.amount,
    required super.concept,
    required super.performedBy,
    super.resultingBalance,
    super.registerId,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  bool get isIncome => movementType.toLowerCase() == 'income';
  bool get isWithdrawal => movementType.toLowerCase() == 'withdrawal';

  double get amountDouble => NumberFormatter.convertFromCentsToDouble(amount);
  String get formattedAmount => NumberFormatter.convertToMoneyLike(amount);

  String get typeLabel => isIncome ? 'Ingreso' : 'Egreso / Gasto';

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

  factory CashMovementInDb.fromJson(Map<String, dynamic> json) {
    return CashMovementInDb(
      id: json['id'] as String? ?? '',
      shiftId: json['shiftId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      movementType: json['movementType'] as String? ?? 'income',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      concept: json['concept'] as String? ?? '',
      performedBy: json['performedBy'] != null
          ? UserInfo.fromJson(json['performedBy'] as Map<String, dynamic>)
          : UserInfo(id: '', name: 'Operador'),
      resultingBalance: (json['resultingBalance'] as num?)?.toInt(),
      registerId: json['registerId'] as String?,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

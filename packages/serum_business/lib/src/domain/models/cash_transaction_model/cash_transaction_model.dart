import 'package:serum_business/src/domain/models/shared/user_info.dart';

class BaseCashTransaction {
  final String registerId;
  final String flowType;
  final String subType;
  final String? paymentMethod;
  final int amount;
  final int resultingBalance;
  final String concept;
  final String? referenceId;
  final UserInfo performedBy;

  BaseCashTransaction({
    required this.registerId,
    required this.flowType,
    required this.subType,
    this.paymentMethod,
    required this.amount,
    required this.resultingBalance,
    required this.concept,
    this.referenceId,
    required this.performedBy,
  });
}

class CreateCashTransaction extends BaseCashTransaction {
  CreateCashTransaction({
    required super.registerId,
    required super.flowType,
    required super.subType,
    super.paymentMethod,
    required super.amount,
    required super.resultingBalance,
    required super.concept,
    super.referenceId,
    required super.performedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'registerId': registerId,
      'flowType': flowType,
      'subType': subType,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'resultingBalance': resultingBalance,
      'concept': concept,
      'referenceId': referenceId,
      'performedBy': performedBy.toJson(),
    };
  }
}

class UpdateCashTransaction {
  final String? paymentMethod;
  final String? concept;

  UpdateCashTransaction({this.paymentMethod, this.concept});

  Map<String, dynamic> toJson() {
    return {
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (concept != null) 'concept': concept,
    };
  }
}

class CashTransactionInDb extends BaseCashTransaction {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  CashTransactionInDb({
    required this.id,
    required super.registerId,
    required super.flowType,
    required super.subType,
    super.paymentMethod,
    required super.amount,
    required super.resultingBalance,
    required super.concept,
    super.referenceId,
    required super.performedBy,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory CashTransactionInDb.fromJson(Map<String, dynamic> json) {
    return CashTransactionInDb(
      id: json['id'] as String,
      registerId: json['registerId'] as String,
      flowType: json['flowType'] as String,
      subType: json['subType'] as String,
      paymentMethod: json['paymentMethod'] as String?,
      amount: json['amount'] as int,
      resultingBalance: json['resultingBalance'] as int,
      concept: json['concept'] as String,
      referenceId: json['referenceId'] as String?,
      performedBy: UserInfo.fromJson(json['performedBy'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

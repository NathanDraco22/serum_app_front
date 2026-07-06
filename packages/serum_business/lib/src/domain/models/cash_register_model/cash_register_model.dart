import 'package:serum_business/src/domain/models/shared/user_info.dart';

class BaseCashRegister {
  final String branchId;
  final String name;
  final bool isOpen;
  final int cashBalance;
  final int cardBalance;
  final int transferBalance;
  final int totalBalance;
  final UserInfo? openedBy;

  BaseCashRegister({
    required this.branchId,
    required this.name,
    this.isOpen = false,
    this.cashBalance = 0,
    this.cardBalance = 0,
    this.transferBalance = 0,
    this.totalBalance = 0,
    this.openedBy,
  });
}

class CreateCashRegister extends BaseCashRegister {
  CreateCashRegister({
    required super.branchId,
    required super.name,
    super.isOpen = false,
    super.cashBalance = 0,
    super.cardBalance = 0,
    super.transferBalance = 0,
    super.totalBalance = 0,
    super.openedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'name': name,
      'isOpen': isOpen,
      'cashBalance': cashBalance,
      'cardBalance': cardBalance,
      'transferBalance': transferBalance,
      'totalBalance': totalBalance,
      if (openedBy != null) 'openedBy': openedBy!.toJson(),
    };
  }
}

class UpdateCashRegister {
  final String? name;
  final bool? isOpen;
  final int? cashBalance;
  final int? cardBalance;
  final int? transferBalance;
  final int? totalBalance;
  final UserInfo? openedBy;

  UpdateCashRegister({
    this.name,
    this.isOpen,
    this.cashBalance,
    this.cardBalance,
    this.transferBalance,
    this.totalBalance,
    this.openedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (isOpen != null) 'isOpen': isOpen,
      if (cashBalance != null) 'cashBalance': cashBalance,
      if (cardBalance != null) 'cardBalance': cardBalance,
      if (transferBalance != null) 'transferBalance': transferBalance,
      if (totalBalance != null) 'totalBalance': totalBalance,
      if (openedBy != null) 'openedBy': openedBy!.toJson(),
    };
  }
}

class CashRegisterInDb extends BaseCashRegister {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  CashRegisterInDb({
    required this.id,
    required super.branchId,
    required super.name,
    super.isOpen = false,
    super.cashBalance = 0,
    super.cardBalance = 0,
    super.transferBalance = 0,
    super.totalBalance = 0,
    super.openedBy,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory CashRegisterInDb.fromJson(Map<String, dynamic> json) {
    return CashRegisterInDb(
      id: json['id'] as String,
      branchId: json['branchId'] as String,
      name: json['name'] as String,
      isOpen: json['isOpen'] as bool? ?? false,
      cashBalance: json['cashBalance'] as int? ?? 0,
      cardBalance: json['cardBalance'] as int? ?? 0,
      transferBalance: json['transferBalance'] as int? ?? 0,
      totalBalance: json['totalBalance'] as int? ?? 0,
      openedBy: json['openedBy'] != null
          ? UserInfo.fromJson(json['openedBy'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

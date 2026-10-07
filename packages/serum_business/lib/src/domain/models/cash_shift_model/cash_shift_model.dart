class BaseCashShift {
  final String userId;
  final String branchId;
  final String notes;
  final String? userName;
  final String? branchName;

  BaseCashShift({
    required this.userId,
    required this.branchId,
    this.notes = '',
    this.userName,
    this.branchName,
  });
}

class CreateCashShift extends BaseCashShift {
  final int initialBalance;

  CreateCashShift({
    required super.userId,
    required super.branchId,
    super.notes = '',
    super.userName,
    super.branchName,
    required this.initialBalance,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'branchId': branchId,
      'notes': notes,
      if (userName != null) 'userName': userName,
      if (branchName != null) 'branchName': branchName,
      'initialBalance': initialBalance,
    };
  }
}

class CloseCashShift {
  final int declaredCash;
  final String notes;

  CloseCashShift({
    required this.declaredCash,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'declaredCash': declaredCash,
      'notes': notes,
    };
  }
}

class UpdateCashShift {
  final String? notes;

  UpdateCashShift({this.notes});

  Map<String, dynamic> toJson() {
    return {
      if (notes != null) 'notes': notes,
    };
  }
}

class CashShiftInDb extends BaseCashShift {
  final String id;
  final String status;
  final int openedAt;
  final int? closedAt;
  final int initialBalance;
  final int cashBalance;
  final int cardBalance;
  final int transferBalance;
  final int totalBalance;
  final int? declaredCash;
  final int? difference;
  final bool isDeleted;
  final int createdAt;
  final int? updatedAt;

  CashShiftInDb({
    required this.id,
    required super.userId,
    required super.branchId,
    super.notes = '',
    super.userName,
    super.branchName,
    this.status = 'OPEN',
    required this.openedAt,
    this.closedAt,
    required this.initialBalance,
    this.cashBalance = 0,
    this.cardBalance = 0,
    this.transferBalance = 0,
    this.totalBalance = 0,
    this.declaredCash,
    this.difference,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOpen => status == 'OPEN';
  double get initialBalanceDouble => initialBalance / 100.0;
  double get cashBalanceDouble => cashBalance / 100.0;
  double get cardBalanceDouble => cardBalance / 100.0;
  double get transferBalanceDouble => transferBalance / 100.0;
  double get totalBalanceDouble => totalBalance / 100.0;
  double get totalCashExpectedDouble => (initialBalance + cashBalance) / 100.0;
  double? get declaredCashDouble =>
      declaredCash != null ? declaredCash! / 100.0 : null;
  double? get differenceDouble =>
      difference != null ? difference! / 100.0 : null;

  factory CashShiftInDb.fromJson(Map<String, dynamic> json) {
    return CashShiftInDb(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      userName: json['userName'] as String?,
      branchName: json['branchName'] as String?,
      status: json['status'] as String? ?? 'OPEN',
      openedAt: json['openedAt'] as int? ?? 0,
      closedAt: json['closedAt'] as int?,
      initialBalance: json['initialBalance'] as int? ?? 0,
      cashBalance: json['cashBalance'] as int? ?? 0,
      cardBalance: json['cardBalance'] as int? ?? 0,
      transferBalance: json['transferBalance'] as int? ?? 0,
      totalBalance: json['totalBalance'] as int? ?? 0,
      declaredCash: json['declaredCash'] as int?,
      difference: json['difference'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int?,
    );
  }
}

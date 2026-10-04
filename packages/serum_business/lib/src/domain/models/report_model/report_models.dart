// Modelos para Reportes Analíticos

// ============================================================================
// 1. REPORTE FINANCIERO (Facturado vs Cobrado)
// ============================================================================

class PaymentMethodsBreakdown {
  final int cash;
  final int card;
  final int transfer;

  const PaymentMethodsBreakdown({
    this.cash = 0,
    this.card = 0,
    this.transfer = 0,
  });

  factory PaymentMethodsBreakdown.fromMap(Map<String, dynamic> map) {
    return PaymentMethodsBreakdown(
      cash: (map['cash'] as num?)?.toInt() ?? 0,
      card: (map['card'] as num?)?.toInt() ?? 0,
      transfer: (map['transfer'] as num?)?.toInt() ?? 0,
    );
  }

  factory PaymentMethodsBreakdown.fromJson(Map<String, dynamic> json) =>
      PaymentMethodsBreakdown.fromMap(json);

  Map<String, dynamic> toMap() => {
        'cash': cash,
        'card': card,
        'transfer': transfer,
      };

  Map<String, dynamic> toJson() => toMap();

  PaymentMethodsBreakdown copyWith({
    int? cash,
    int? card,
    int? transfer,
  }) {
    return PaymentMethodsBreakdown(
      cash: cash ?? this.cash,
      card: card ?? this.card,
      transfer: transfer ?? this.transfer,
    );
  }
}

class FinancialBranchReport {
  final String branchId;
  final String branchName;
  final int totalBilled;
  final int totalCollected;
  final int pendingReceivables;
  final int ordersCount;
  final int transactionsCount;
  final PaymentMethodsBreakdown paymentMethods;

  const FinancialBranchReport({
    required this.branchId,
    this.branchName = '',
    this.totalBilled = 0,
    this.totalCollected = 0,
    this.pendingReceivables = 0,
    this.ordersCount = 0,
    this.transactionsCount = 0,
    this.paymentMethods = const PaymentMethodsBreakdown(),
  });

  factory FinancialBranchReport.fromMap(Map<String, dynamic> map) {
    return FinancialBranchReport(
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      totalBilled: (map['totalBilled'] as num?)?.toInt() ?? 0,
      totalCollected: (map['totalCollected'] as num?)?.toInt() ?? 0,
      pendingReceivables: (map['pendingReceivables'] as num?)?.toInt() ?? 0,
      ordersCount: (map['ordersCount'] as num?)?.toInt() ?? 0,
      transactionsCount: (map['transactionsCount'] as num?)?.toInt() ?? 0,
      paymentMethods: map['paymentMethods'] is Map<String, dynamic>
          ? PaymentMethodsBreakdown.fromMap(
              map['paymentMethods'] as Map<String, dynamic>)
          : const PaymentMethodsBreakdown(),
    );
  }

  factory FinancialBranchReport.fromJson(Map<String, dynamic> json) =>
      FinancialBranchReport.fromMap(json);

  Map<String, dynamic> toMap() => {
        'branchId': branchId,
        'branchName': branchName,
        'totalBilled': totalBilled,
        'totalCollected': totalCollected,
        'pendingReceivables': pendingReceivables,
        'ordersCount': ordersCount,
        'transactionsCount': transactionsCount,
        'paymentMethods': paymentMethods.toMap(),
      };

  Map<String, dynamic> toJson() => toMap();

  FinancialBranchReport copyWith({
    String? branchId,
    String? branchName,
    int? totalBilled,
    int? totalCollected,
    int? pendingReceivables,
    int? ordersCount,
    int? transactionsCount,
    PaymentMethodsBreakdown? paymentMethods,
  }) {
    return FinancialBranchReport(
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      totalBilled: totalBilled ?? this.totalBilled,
      totalCollected: totalCollected ?? this.totalCollected,
      pendingReceivables: pendingReceivables ?? this.pendingReceivables,
      ordersCount: ordersCount ?? this.ordersCount,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}

class FinancialSummaryReport {
  final int totalBilled;
  final int totalCollected;
  final int pendingReceivables;
  final int ordersCount;
  final int transactionsCount;
  final PaymentMethodsBreakdown paymentMethods;

  const FinancialSummaryReport({
    this.totalBilled = 0,
    this.totalCollected = 0,
    this.pendingReceivables = 0,
    this.ordersCount = 0,
    this.transactionsCount = 0,
    this.paymentMethods = const PaymentMethodsBreakdown(),
  });

  factory FinancialSummaryReport.fromMap(Map<String, dynamic> map) {
    return FinancialSummaryReport(
      totalBilled: (map['totalBilled'] as num?)?.toInt() ?? 0,
      totalCollected: (map['totalCollected'] as num?)?.toInt() ?? 0,
      pendingReceivables: (map['pendingReceivables'] as num?)?.toInt() ?? 0,
      ordersCount: (map['ordersCount'] as num?)?.toInt() ?? 0,
      transactionsCount: (map['transactionsCount'] as num?)?.toInt() ?? 0,
      paymentMethods: map['paymentMethods'] is Map<String, dynamic>
          ? PaymentMethodsBreakdown.fromMap(
              map['paymentMethods'] as Map<String, dynamic>)
          : const PaymentMethodsBreakdown(),
    );
  }

  factory FinancialSummaryReport.fromJson(Map<String, dynamic> json) =>
      FinancialSummaryReport.fromMap(json);

  Map<String, dynamic> toMap() => {
        'totalBilled': totalBilled,
        'totalCollected': totalCollected,
        'pendingReceivables': pendingReceivables,
        'ordersCount': ordersCount,
        'transactionsCount': transactionsCount,
        'paymentMethods': paymentMethods.toMap(),
      };

  Map<String, dynamic> toJson() => toMap();

  FinancialSummaryReport copyWith({
    int? totalBilled,
    int? totalCollected,
    int? pendingReceivables,
    int? ordersCount,
    int? transactionsCount,
    PaymentMethodsBreakdown? paymentMethods,
  }) {
    return FinancialSummaryReport(
      totalBilled: totalBilled ?? this.totalBilled,
      totalCollected: totalCollected ?? this.totalCollected,
      pendingReceivables: pendingReceivables ?? this.pendingReceivables,
      ordersCount: ordersCount ?? this.ordersCount,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}

class FinancialReportResponse {
  final int startDate;
  final int endDate;
  final FinancialSummaryReport summary;
  final List<FinancialBranchReport> byBranch;

  const FinancialReportResponse({
    required this.startDate,
    required this.endDate,
    required this.summary,
    this.byBranch = const [],
  });

  factory FinancialReportResponse.fromMap(Map<String, dynamic> map) {
    return FinancialReportResponse(
      startDate: (map['startDate'] as num?)?.toInt() ?? 0,
      endDate: (map['endDate'] as num?)?.toInt() ?? 0,
      summary: map['summary'] is Map<String, dynamic>
          ? FinancialSummaryReport.fromMap(
              map['summary'] as Map<String, dynamic>)
          : const FinancialSummaryReport(),
      byBranch: (map['byBranch'] as List<dynamic>?)
              ?.map((e) =>
                  FinancialBranchReport.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory FinancialReportResponse.fromJson(Map<String, dynamic> json) =>
      FinancialReportResponse.fromMap(json);

  Map<String, dynamic> toMap() => {
        'startDate': startDate,
        'endDate': endDate,
        'summary': summary.toMap(),
        'byBranch': byBranch.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

// ============================================================================
// 2. REPORTE DE MÉDICOS REFERENTES (Top Doctors)
// ============================================================================

class DoctorOrderItem {
  final String? doctorId;
  final String doctorName;
  final String specialty;
  final int totalOrders;
  final int totalRevenue;

  const DoctorOrderItem({
    this.doctorId,
    required this.doctorName,
    this.specialty = '',
    this.totalOrders = 0,
    this.totalRevenue = 0,
  });

  factory DoctorOrderItem.fromMap(Map<String, dynamic> map) {
    return DoctorOrderItem(
      doctorId: map['doctorId']?.toString(),
      doctorName: map['doctorName']?.toString() ?? 'Sin Médico',
      specialty: map['specialty']?.toString() ?? '',
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toInt() ?? 0,
    );
  }

  factory DoctorOrderItem.fromJson(Map<String, dynamic> json) =>
      DoctorOrderItem.fromMap(json);

  Map<String, dynamic> toMap() => {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'specialty': specialty,
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
      };

  Map<String, dynamic> toJson() => toMap();

  DoctorOrderItem copyWith({
    String? doctorId,
    String? doctorName,
    String? specialty,
    int? totalOrders,
    int? totalRevenue,
  }) {
    return DoctorOrderItem(
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
    );
  }
}

class TopDoctorsBranchReport {
  final String branchId;
  final String branchName;
  final List<DoctorOrderItem> doctors;

  const TopDoctorsBranchReport({
    required this.branchId,
    this.branchName = '',
    this.doctors = const [],
  });

  factory TopDoctorsBranchReport.fromMap(Map<String, dynamic> map) {
    return TopDoctorsBranchReport(
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      doctors: (map['doctors'] as List<dynamic>?)
              ?.map((e) => DoctorOrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory TopDoctorsBranchReport.fromJson(Map<String, dynamic> json) =>
      TopDoctorsBranchReport.fromMap(json);

  Map<String, dynamic> toMap() => {
        'branchId': branchId,
        'branchName': branchName,
        'doctors': doctors.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

class TopDoctorsSummary {
  final int totalOrders;
  final int totalRevenue;
  final List<DoctorOrderItem> topDoctors;

  const TopDoctorsSummary({
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.topDoctors = const [],
  });

  factory TopDoctorsSummary.fromMap(Map<String, dynamic> map) {
    return TopDoctorsSummary(
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toInt() ?? 0,
      topDoctors: (map['topDoctors'] as List<dynamic>?)
              ?.map((e) => DoctorOrderItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory TopDoctorsSummary.fromJson(Map<String, dynamic> json) =>
      TopDoctorsSummary.fromMap(json);

  Map<String, dynamic> toMap() => {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'topDoctors': topDoctors.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

class TopDoctorsReportResponse {
  final int startDate;
  final int endDate;
  final TopDoctorsSummary summary;
  final List<TopDoctorsBranchReport> byBranch;

  const TopDoctorsReportResponse({
    required this.startDate,
    required this.endDate,
    required this.summary,
    this.byBranch = const [],
  });

  factory TopDoctorsReportResponse.fromMap(Map<String, dynamic> map) {
    return TopDoctorsReportResponse(
      startDate: (map['startDate'] as num?)?.toInt() ?? 0,
      endDate: (map['endDate'] as num?)?.toInt() ?? 0,
      summary: map['summary'] is Map<String, dynamic>
          ? TopDoctorsSummary.fromMap(map['summary'] as Map<String, dynamic>)
          : const TopDoctorsSummary(),
      byBranch: (map['byBranch'] as List<dynamic>?)
              ?.map((e) =>
                  TopDoctorsBranchReport.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory TopDoctorsReportResponse.fromJson(Map<String, dynamic> json) =>
      TopDoctorsReportResponse.fromMap(json);

  Map<String, dynamic> toMap() => {
        'startDate': startDate,
        'endDate': endDate,
        'summary': summary.toMap(),
        'byBranch': byBranch.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

// ============================================================================
// 3. REPORTE DE VOLUMEN DE EXÁMENES (Lab Tests / Packs)
// ============================================================================

class LabTestVolumeItem {
  final String labTestId;
  final String name;
  final String category;
  final bool isPack;
  final int timesOrdered;
  final int totalRevenue;

  const LabTestVolumeItem({
    required this.labTestId,
    required this.name,
    this.category = '',
    this.isPack = false,
    this.timesOrdered = 0,
    this.totalRevenue = 0,
  });

  factory LabTestVolumeItem.fromMap(Map<String, dynamic> map) {
    return LabTestVolumeItem(
      labTestId: map['labTestId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      isPack: map['isPack'] as bool? ?? false,
      timesOrdered: (map['timesOrdered'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toInt() ?? 0,
    );
  }

  factory LabTestVolumeItem.fromJson(Map<String, dynamic> json) =>
      LabTestVolumeItem.fromMap(json);

  Map<String, dynamic> toMap() => {
        'labTestId': labTestId,
        'name': name,
        'category': category,
        'isPack': isPack,
        'timesOrdered': timesOrdered,
        'totalRevenue': totalRevenue,
      };

  Map<String, dynamic> toJson() => toMap();

  LabTestVolumeItem copyWith({
    String? labTestId,
    String? name,
    String? category,
    bool? isPack,
    int? timesOrdered,
    int? totalRevenue,
  }) {
    return LabTestVolumeItem(
      labTestId: labTestId ?? this.labTestId,
      name: name ?? this.name,
      category: category ?? this.category,
      isPack: isPack ?? this.isPack,
      timesOrdered: timesOrdered ?? this.timesOrdered,
      totalRevenue: totalRevenue ?? this.totalRevenue,
    );
  }
}

class LabTestsVolumeBranchReport {
  final String branchId;
  final String branchName;
  final List<LabTestVolumeItem> tests;

  const LabTestsVolumeBranchReport({
    required this.branchId,
    this.branchName = '',
    this.tests = const [],
  });

  factory LabTestsVolumeBranchReport.fromMap(Map<String, dynamic> map) {
    return LabTestsVolumeBranchReport(
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      tests: (map['tests'] as List<dynamic>?)
              ?.map((e) => LabTestVolumeItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory LabTestsVolumeBranchReport.fromJson(Map<String, dynamic> json) =>
      LabTestsVolumeBranchReport.fromMap(json);

  Map<String, dynamic> toMap() => {
        'branchId': branchId,
        'branchName': branchName,
        'tests': tests.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

class LabTestsVolumeSummary {
  final int totalTestsCount;
  final int totalRevenue;
  final List<LabTestVolumeItem> topTests;

  const LabTestsVolumeSummary({
    this.totalTestsCount = 0,
    this.totalRevenue = 0,
    this.topTests = const [],
  });

  factory LabTestsVolumeSummary.fromMap(Map<String, dynamic> map) {
    return LabTestsVolumeSummary(
      totalTestsCount: (map['totalTestsCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toInt() ?? 0,
      topTests: (map['topTests'] as List<dynamic>?)
              ?.map((e) => LabTestVolumeItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory LabTestsVolumeSummary.fromJson(Map<String, dynamic> json) =>
      LabTestsVolumeSummary.fromMap(json);

  Map<String, dynamic> toMap() => {
        'totalTestsCount': totalTestsCount,
        'totalRevenue': totalRevenue,
        'topTests': topTests.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

class LabTestsVolumeReportResponse {
  final int startDate;
  final int endDate;
  final String source;
  final LabTestsVolumeSummary summary;
  final List<LabTestsVolumeBranchReport> byBranch;

  const LabTestsVolumeReportResponse({
    required this.startDate,
    required this.endDate,
    this.source = 'orders',
    required this.summary,
    this.byBranch = const [],
  });

  factory LabTestsVolumeReportResponse.fromMap(Map<String, dynamic> map) {
    return LabTestsVolumeReportResponse(
      startDate: (map['startDate'] as num?)?.toInt() ?? 0,
      endDate: (map['endDate'] as num?)?.toInt() ?? 0,
      source: map['source']?.toString() ?? 'orders',
      summary: map['summary'] is Map<String, dynamic>
          ? LabTestsVolumeSummary.fromMap(map['summary'] as Map<String, dynamic>)
          : const LabTestsVolumeSummary(),
      byBranch: (map['byBranch'] as List<dynamic>?)
              ?.map((e) =>
                  LabTestsVolumeBranchReport.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory LabTestsVolumeReportResponse.fromJson(Map<String, dynamic> json) =>
      LabTestsVolumeReportResponse.fromMap(json);

  Map<String, dynamic> toMap() => {
        'startDate': startDate,
        'endDate': endDate,
        'source': source,
        'summary': summary.toMap(),
        'byBranch': byBranch.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

// ============================================================================
// 4. REPORTE DE CUENTAS POR COBRAR (Saldos Pendientes)
// ============================================================================

class PendingBalanceItem {
  final String orderId;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final int totalPrice;
  final int paidAmount;
  final int pendingAmount;
  final int orderDate;
  final int daysPending;

  const PendingBalanceItem({
    required this.orderId,
    required this.patientId,
    required this.patientName,
    this.patientPhone = '',
    required this.totalPrice,
    required this.paidAmount,
    required this.pendingAmount,
    required this.orderDate,
    this.daysPending = 0,
  });

  factory PendingBalanceItem.fromMap(Map<String, dynamic> map) {
    return PendingBalanceItem(
      orderId: map['orderId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      patientName: map['patientName']?.toString() ?? '',
      patientPhone: map['patientPhone']?.toString() ?? '',
      totalPrice: (map['totalPrice'] as num?)?.toInt() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toInt() ?? 0,
      pendingAmount: (map['pendingAmount'] as num?)?.toInt() ?? 0,
      orderDate: (map['orderDate'] as num?)?.toInt() ?? 0,
      daysPending: (map['daysPending'] as num?)?.toInt() ?? 0,
    );
  }

  factory PendingBalanceItem.fromJson(Map<String, dynamic> json) =>
      PendingBalanceItem.fromMap(json);

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'patientId': patientId,
        'patientName': patientName,
        'patientPhone': patientPhone,
        'totalPrice': totalPrice,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'orderDate': orderDate,
        'daysPending': daysPending,
      };

  Map<String, dynamic> toJson() => toMap();

  PendingBalanceItem copyWith({
    String? orderId,
    String? patientId,
    String? patientName,
    String? patientPhone,
    int? totalPrice,
    int? paidAmount,
    int? pendingAmount,
    int? orderDate,
    int? daysPending,
  }) {
    return PendingBalanceItem(
      orderId: orderId ?? this.orderId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      totalPrice: totalPrice ?? this.totalPrice,
      paidAmount: paidAmount ?? this.paidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      orderDate: orderDate ?? this.orderDate,
      daysPending: daysPending ?? this.daysPending,
    );
  }
}

class PendingBalancesBranchReport {
  final String branchId;
  final String branchName;
  final int totalPendingAmount;
  final int ordersCount;
  final List<PendingBalanceItem> orders;

  const PendingBalancesBranchReport({
    required this.branchId,
    this.branchName = '',
    this.totalPendingAmount = 0,
    this.ordersCount = 0,
    this.orders = const [],
  });

  factory PendingBalancesBranchReport.fromMap(Map<String, dynamic> map) {
    return PendingBalancesBranchReport(
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      totalPendingAmount: (map['totalPendingAmount'] as num?)?.toInt() ?? 0,
      ordersCount: (map['ordersCount'] as num?)?.toInt() ?? 0,
      orders: (map['orders'] as List<dynamic>?)
              ?.map((e) =>
                  PendingBalanceItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory PendingBalancesBranchReport.fromJson(Map<String, dynamic> json) =>
      PendingBalancesBranchReport.fromMap(json);

  Map<String, dynamic> toMap() => {
        'branchId': branchId,
        'branchName': branchName,
        'totalPendingAmount': totalPendingAmount,
        'ordersCount': ordersCount,
        'orders': orders.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

class PendingBalancesSummary {
  final int totalPendingAmount;
  final int ordersCount;

  const PendingBalancesSummary({
    this.totalPendingAmount = 0,
    this.ordersCount = 0,
  });

  factory PendingBalancesSummary.fromMap(Map<String, dynamic> map) {
    return PendingBalancesSummary(
      totalPendingAmount: (map['totalPendingAmount'] as num?)?.toInt() ?? 0,
      ordersCount: (map['ordersCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory PendingBalancesSummary.fromJson(Map<String, dynamic> json) =>
      PendingBalancesSummary.fromMap(json);

  Map<String, dynamic> toMap() => {
        'totalPendingAmount': totalPendingAmount,
        'ordersCount': ordersCount,
      };

  Map<String, dynamic> toJson() => toMap();
}

class PendingBalancesReportResponse {
  final int startDate;
  final int endDate;
  final PendingBalancesSummary summary;
  final List<PendingBalancesBranchReport> byBranch;

  const PendingBalancesReportResponse({
    required this.startDate,
    required this.endDate,
    required this.summary,
    this.byBranch = const [],
  });

  factory PendingBalancesReportResponse.fromMap(Map<String, dynamic> map) {
    return PendingBalancesReportResponse(
      startDate: (map['startDate'] as num?)?.toInt() ?? 0,
      endDate: (map['endDate'] as num?)?.toInt() ?? 0,
      summary: map['summary'] is Map<String, dynamic>
          ? PendingBalancesSummary.fromMap(
              map['summary'] as Map<String, dynamic>)
          : const PendingBalancesSummary(),
      byBranch: (map['byBranch'] as List<dynamic>?)
              ?.map((e) =>
                  PendingBalancesBranchReport.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory PendingBalancesReportResponse.fromJson(Map<String, dynamic> json) =>
      PendingBalancesReportResponse.fromMap(json);

  Map<String, dynamic> toMap() => {
        'startDate': startDate,
        'endDate': endDate,
        'summary': summary.toMap(),
        'byBranch': byBranch.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

// ============================================================================
// 5. REPORTE DE AUDITORÍA DE TURNOS (CashShifts)
// ============================================================================

class ShiftAuditItem {
  final String shiftId;
  final String userId;
  final String userName;
  final int openedAt;
  final int? closedAt;
  final int initialBalance;
  final int cashBalance;
  final int cardBalance;
  final int transferBalance;
  final int totalBalance;
  final int? declaredCash;
  final int? difference;
  final String notes;

  const ShiftAuditItem({
    required this.shiftId,
    required this.userId,
    this.userName = '',
    required this.openedAt,
    this.closedAt,
    this.initialBalance = 0,
    this.cashBalance = 0,
    this.cardBalance = 0,
    this.transferBalance = 0,
    this.totalBalance = 0,
    this.declaredCash,
    this.difference,
    this.notes = '',
  });

  factory ShiftAuditItem.fromMap(Map<String, dynamic> map) {
    return ShiftAuditItem(
      shiftId: map['shiftId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      openedAt: (map['openedAt'] as num?)?.toInt() ?? 0,
      closedAt: (map['closedAt'] as num?)?.toInt(),
      initialBalance: (map['initialBalance'] as num?)?.toInt() ?? 0,
      cashBalance: (map['cashBalance'] as num?)?.toInt() ?? 0,
      cardBalance: (map['cardBalance'] as num?)?.toInt() ?? 0,
      transferBalance: (map['transferBalance'] as num?)?.toInt() ?? 0,
      totalBalance: (map['totalBalance'] as num?)?.toInt() ?? 0,
      declaredCash: (map['declaredCash'] as num?)?.toInt(),
      difference: (map['difference'] as num?)?.toInt(),
      notes: map['notes']?.toString() ?? '',
    );
  }

  factory ShiftAuditItem.fromJson(Map<String, dynamic> json) =>
      ShiftAuditItem.fromMap(json);

  Map<String, dynamic> toMap() => {
        'shiftId': shiftId,
        'userId': userId,
        'userName': userName,
        'openedAt': openedAt,
        'closedAt': closedAt,
        'initialBalance': initialBalance,
        'cashBalance': cashBalance,
        'cardBalance': cardBalance,
        'transferBalance': transferBalance,
        'totalBalance': totalBalance,
        'declaredCash': declaredCash,
        'difference': difference,
        'notes': notes,
      };

  Map<String, dynamic> toJson() => toMap();

  ShiftAuditItem copyWith({
    String? shiftId,
    String? userId,
    String? userName,
    int? openedAt,
    int? closedAt,
    int? initialBalance,
    int? cashBalance,
    int? cardBalance,
    int? transferBalance,
    int? totalBalance,
    int? declaredCash,
    int? difference,
    String? notes,
  }) {
    return ShiftAuditItem(
      shiftId: shiftId ?? this.shiftId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      initialBalance: initialBalance ?? this.initialBalance,
      cashBalance: cashBalance ?? this.cashBalance,
      cardBalance: cardBalance ?? this.cardBalance,
      transferBalance: transferBalance ?? this.transferBalance,
      totalBalance: totalBalance ?? this.totalBalance,
      declaredCash: declaredCash ?? this.declaredCash,
      difference: difference ?? this.difference,
      notes: notes ?? this.notes,
    );
  }
}

class ShiftsAuditBranchReport {
  final String branchId;
  final String branchName;
  final int totalShifts;
  final int totalDiscrepancies;
  final int netDifference;
  final List<ShiftAuditItem> shifts;

  const ShiftsAuditBranchReport({
    required this.branchId,
    this.branchName = '',
    this.totalShifts = 0,
    this.totalDiscrepancies = 0,
    this.netDifference = 0,
    this.shifts = const [],
  });

  factory ShiftsAuditBranchReport.fromMap(Map<String, dynamic> map) {
    return ShiftsAuditBranchReport(
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      totalShifts: (map['totalShifts'] as num?)?.toInt() ?? 0,
      totalDiscrepancies: (map['totalDiscrepancies'] as num?)?.toInt() ?? 0,
      netDifference: (map['netDifference'] as num?)?.toInt() ?? 0,
      shifts: (map['shifts'] as List<dynamic>?)
              ?.map((e) => ShiftAuditItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory ShiftsAuditBranchReport.fromJson(Map<String, dynamic> json) =>
      ShiftsAuditBranchReport.fromMap(json);

  Map<String, dynamic> toMap() => {
        'branchId': branchId,
        'branchName': branchName,
        'totalShifts': totalShifts,
        'totalDiscrepancies': totalDiscrepancies,
        'netDifference': netDifference,
        'shifts': shifts.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

class ShiftsAuditSummary {
  final int totalShifts;
  final int totalDiscrepancies;
  final int netDifference;

  const ShiftsAuditSummary({
    this.totalShifts = 0,
    this.totalDiscrepancies = 0,
    this.netDifference = 0,
  });

  factory ShiftsAuditSummary.fromMap(Map<String, dynamic> map) {
    return ShiftsAuditSummary(
      totalShifts: (map['totalShifts'] as num?)?.toInt() ?? 0,
      totalDiscrepancies: (map['totalDiscrepancies'] as num?)?.toInt() ?? 0,
      netDifference: (map['netDifference'] as num?)?.toInt() ?? 0,
    );
  }

  factory ShiftsAuditSummary.fromJson(Map<String, dynamic> json) =>
      ShiftsAuditSummary.fromMap(json);

  Map<String, dynamic> toMap() => {
        'totalShifts': totalShifts,
        'totalDiscrepancies': totalDiscrepancies,
        'netDifference': netDifference,
      };

  Map<String, dynamic> toJson() => toMap();
}

class ShiftsAuditReportResponse {
  final int startDate;
  final int endDate;
  final ShiftsAuditSummary summary;
  final List<ShiftsAuditBranchReport> byBranch;

  const ShiftsAuditReportResponse({
    required this.startDate,
    required this.endDate,
    required this.summary,
    this.byBranch = const [],
  });

  factory ShiftsAuditReportResponse.fromMap(Map<String, dynamic> map) {
    return ShiftsAuditReportResponse(
      startDate: (map['startDate'] as num?)?.toInt() ?? 0,
      endDate: (map['endDate'] as num?)?.toInt() ?? 0,
      summary: map['summary'] is Map<String, dynamic>
          ? ShiftsAuditSummary.fromMap(map['summary'] as Map<String, dynamic>)
          : const ShiftsAuditSummary(),
      byBranch: (map['byBranch'] as List<dynamic>?)
              ?.map((e) =>
                  ShiftsAuditBranchReport.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory ShiftsAuditReportResponse.fromJson(Map<String, dynamic> json) =>
      ShiftsAuditReportResponse.fromMap(json);

  Map<String, dynamic> toMap() => {
        'startDate': startDate,
        'endDate': endDate,
        'summary': summary.toMap(),
        'byBranch': byBranch.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toJson() => toMap();
}

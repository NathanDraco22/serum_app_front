import 'package:serum_business/src/domain/models/shared/order_test_result.dart';
import 'package:serum_business/src/domain/models/shared/user_info.dart';

class PatientInfo {
  final String name;
  final int dateOfBirth;
  final String gender;
  final String phone;
  final String address;
  final String? cardId;
  final String? email;

  PatientInfo({
    required this.name,
    this.dateOfBirth = 0,
    this.gender = 'M',
    this.phone = '',
    this.address = '',
    this.cardId,
    this.email,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      name: json['name'] as String? ?? '',
      dateOfBirth: (json['dateOfBirth'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? 'M',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      cardId: json['cardId'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phone': phone,
      'address': address,
      if (cardId != null) 'cardId': cardId,
      if (email != null) 'email': email,
    };
  }
}

class DoctorInfo {
  final String name;
  final String specialty;
  final String phone;
  final String? cardId;
  final String? email;

  DoctorInfo({
    required this.name,
    this.specialty = 'Medicina General',
    this.phone = '',
    this.cardId,
    this.email,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      name: json['name'] as String? ?? '',
      specialty: json['specialty'] as String? ?? 'Medicina General',
      phone: json['phone'] as String? ?? '',
      cardId: json['cardId'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialty': specialty,
      'phone': phone,
      if (cardId != null) 'cardId': cardId,
      if (email != null) 'email': email,
    };
  }
}

class OrderItem {
  final String labTestId;
  final String name;
  final int salePriceApplied;
  final bool isPack;

  OrderItem({
    required this.labTestId,
    required this.name,
    required this.salePriceApplied,
    this.isPack = false,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      labTestId: json['labTestId'] as String? ?? json['examId'] as String? ?? '',
      name: json['name'] as String? ?? json['examName'] as String? ?? '',
      salePriceApplied: (json['salePriceApplied'] as num?)?.toInt() ?? 0,
      isPack: json['isPack'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labTestId': labTestId,
      'name': name,
      'salePriceApplied': salePriceApplied,
      'isPack': isPack,
    };
  }
}

class BaseOrder {
  final String patientId;
  final String branchId;
  final String? doctorId;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;
  final String? quotationId;
  final List<OrderItem> items;
  final int totalPrice;
  final int paidAmount;
  final String status;
  final List<OrderTestResult> results;

  // Backward compatibility getters
  String get examId => items.isNotEmpty ? items.first.labTestId : '';
  String get examName => items.isNotEmpty ? items.map((e) => e.name).join(', ') : '';
  int get salePriceApplied => totalPrice > 0 ? totalPrice : (items.isNotEmpty ? items.fold(0, (sum, i) => sum + i.salePriceApplied) : 0);

  BaseOrder({
    required this.patientId,
    required this.branchId,
    this.doctorId,
    this.patientInfo,
    this.doctorInfo,
    this.quotationId,
    this.items = const [],
    this.totalPrice = 0,
    this.paidAmount = 0,
    this.status = "pending",
    this.results = const [],
  });
}

class CreateOrder extends BaseOrder {
  CreateOrder({
    required super.patientId,
    required super.branchId,
    super.doctorId,
    super.patientInfo,
    super.doctorInfo,
    super.quotationId,
    super.items = const [],
    super.totalPrice = 0,
    super.paidAmount = 0,
    super.status = "pending",
    super.results = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'branchId': branchId,
      if (doctorId != null) 'doctorId': doctorId,
      if (patientInfo != null) 'patientInfo': patientInfo!.toJson(),
      if (doctorInfo != null) 'doctorInfo': doctorInfo!.toJson(),
      'quotationId': quotationId,
      'items': items.map((e) => e.toJson()).toList(),
      'totalPrice': totalPrice > 0 ? totalPrice : salePriceApplied,
      'paidAmount': paidAmount,
      'status': status,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}

class UpdateOrder {
  final String? patientId;
  final String? doctorId;
  final PatientInfo? patientInfo;
  final DoctorInfo? doctorInfo;
  final String? quotationId;
  final List<OrderItem>? items;
  final int? totalPrice;
  final int? paidAmount;
  final String? status;
  final List<OrderTestResult>? results;
  final String? branchId;

  UpdateOrder({
    this.patientId,
    this.doctorId,
    this.patientInfo,
    this.doctorInfo,
    this.quotationId,
    this.items,
    this.totalPrice,
    this.paidAmount,
    this.status,
    this.results,
    this.branchId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (patientId != null) 'patientId': patientId,
      if (doctorId != null) 'doctorId': doctorId,
      if (patientInfo != null) 'patientInfo': patientInfo!.toJson(),
      if (doctorInfo != null) 'doctorInfo': doctorInfo!.toJson(),
      if (quotationId != null) 'quotationId': quotationId,
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (paidAmount != null) 'paidAmount': paidAmount,
      if (status != null) 'status': status,
      if (results != null)
        'results': results!.map((e) => e.toJson()).toList(),
      if (branchId != null) 'branchId': branchId,
    };
  }
}

class OrderPayRequest {
  final int amount;
  final String? shiftId;
  final String? registerId;
  final String paymentMethod;
  final UserInfo performedBy;

  OrderPayRequest({
    required this.amount,
    this.shiftId,
    this.registerId,
    required this.paymentMethod,
    required this.performedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      if (shiftId != null) 'shiftId': shiftId,
      if (registerId != null) 'registerId': registerId,
      'paymentMethod': paymentMethod,
      'performedBy': performedBy.toJson(),
    };
  }
}

class OrderInDb extends BaseOrder {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  OrderInDb({
    required this.id,
    required super.patientId,
    required super.branchId,
    super.doctorId,
    super.patientInfo,
    super.doctorInfo,
    super.quotationId,
    super.items = const [],
    super.totalPrice = 0,
    super.paidAmount = 0,
    super.status = "pending",
    super.results = const [],
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory OrderInDb.fromJson(Map<String, dynamic> json) {
    List<OrderItem> parsedItems = [];
    if (json['items'] != null) {
      parsedItems = (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['examId'] != null) {
      parsedItems = [
        OrderItem(
          labTestId: json['examId'] as String,
          name: json['examName'] as String? ?? '',
          salePriceApplied: (json['salePriceApplied'] as num?)?.toInt() ?? 0,
        )
      ];
    }

    final int total = (json['totalPrice'] as num?)?.toInt() ??
        (json['salePriceApplied'] as num?)?.toInt() ??
        parsedItems.fold<int>(0, (sum, i) => sum + i.salePriceApplied);

    final patientInfoRaw = json['patientInfo'];
    final doctorInfoRaw = json['doctorInfo'];

    return OrderInDb(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      branchId: json['branchId'] as String? ?? '',
      doctorId: json['doctorId'] as String?,
      patientInfo: patientInfoRaw != null
          ? PatientInfo.fromJson(patientInfoRaw as Map<String, dynamic>)
          : null,
      doctorInfo: doctorInfoRaw != null
          ? DoctorInfo.fromJson(doctorInfoRaw as Map<String, dynamic>)
          : null,
      quotationId: json['quotationId'] as String?,
      items: parsedItems,
      totalPrice: total,
      paidAmount: (json['paidAmount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? "pending",
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => OrderTestResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

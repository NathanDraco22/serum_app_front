import 'package:serum_business/src/domain/models/shared/included_test.dart';

class BaseExam {
  final String name;
  final String commercialCategory;
  final int salePrice;
  final String currency;
  final List<IncludedTest> includedTests;

  BaseExam({
    required this.name,
    required this.commercialCategory,
    required this.salePrice,
    required this.currency,
    this.includedTests = const [],
  });
}

class CreateExam extends BaseExam {
  CreateExam({
    required super.name,
    required super.commercialCategory,
    required super.salePrice,
    required super.currency,
    super.includedTests = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'commercialCategory': commercialCategory,
      'salePrice': salePrice,
      'currency': currency,
      'includedTests': includedTests.map((e) => e.toJson()).toList(),
    };
  }
}

class UpdateExam {
  final String? name;
  final String? commercialCategory;
  final int? salePrice;
  final String? currency;
  final List<IncludedTest>? includedTests;

  UpdateExam({
    this.name,
    this.commercialCategory,
    this.salePrice,
    this.currency,
    this.includedTests,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (commercialCategory != null) 'commercialCategory': commercialCategory,
      if (salePrice != null) 'salePrice': salePrice,
      if (currency != null) 'currency': currency,
      if (includedTests != null)
        'includedTests': includedTests!.map((e) => e.toJson()).toList(),
    };
  }
}

class ExamInDb extends BaseExam {
  final String id;
  final int createdAt;
  final int? updatedAt;
  final bool isDeleted;

  ExamInDb({
    required this.id,
    required super.name,
    required super.commercialCategory,
    required super.salePrice,
    required super.currency,
    super.includedTests = const [],
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory ExamInDb.fromJson(Map<String, dynamic> json) {
    return ExamInDb(
      id: json['id'] as String,
      name: json['name'] as String,
      commercialCategory: json['commercialCategory'] as String,
      salePrice: json['salePrice'] as int,
      currency: json['currency'] as String,
      includedTests: (json['includedTests'] as List<dynamic>?)
              ?.map((e) => IncludedTest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

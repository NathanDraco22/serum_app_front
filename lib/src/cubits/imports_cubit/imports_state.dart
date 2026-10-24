import 'package:serum_business/serum_business.dart';

abstract class ImportsState {
  const ImportsState();
}

class ImportsInitial extends ImportsState {
  const ImportsInitial();
}

class ImportsLoading extends ImportsState {
  final String? message;

  const ImportsLoading({this.message});
}

class ImportsSuccess extends ImportsState {
  final ImportCatalogResult result;

  const ImportsSuccess(this.result);
}

class ImportsPricesSuccess extends ImportsState {
  final ImportBranchPricesResult result;

  const ImportsPricesSuccess(this.result);
}

class ImportsFailure extends ImportsState {
  final String message;

  const ImportsFailure(this.message);
}

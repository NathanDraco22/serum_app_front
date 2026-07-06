part of 'read_branches_cubit.dart';

sealed class ReadBranchState {}

final class ReadBranchInitial extends ReadBranchState {}

final class ReadBranchLoading extends ReadBranchState {}

class ReadBranchSuccess extends ReadBranchState {
  final List<BranchInDb> items;
  List<BranchInDb> newItems;
  List<BranchInDb> updatedItems;
  List<BranchInDb> deletedItems;

  ReadBranchSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadBranchRefreshing extends ReadBranchSuccess {
  ReadBranchRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadBranchRefreshing.fromSuccess(
    ReadBranchSuccess success,
  ) =>
      ReadBranchRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadBranchError extends ReadBranchState {
  final String message;
  ReadBranchError(this.message);
}

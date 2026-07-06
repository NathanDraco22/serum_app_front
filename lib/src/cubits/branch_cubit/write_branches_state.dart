part of 'write_branches_cubit.dart';

sealed class WriteBranchState {}

final class WriteBranchInitial extends WriteBranchState {}

final class WritingBranch extends WriteBranchState {}

class WriteBranchSuccess extends WriteBranchState {
  final BranchInDb item;
  WriteBranchSuccess(this.item);
}

final class BranchCreated extends WriteBranchSuccess {
  BranchCreated(super.item);
}

final class BranchUpdated extends WriteBranchSuccess {
  BranchUpdated(super.item);
}

final class BranchDeleted extends WriteBranchSuccess {
  BranchDeleted(super.item);
}

final class WriteBranchError extends WriteBranchState {
  final String message;
  WriteBranchError(this.message);
}

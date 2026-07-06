import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_branches_state.dart';

class WriteBranchCubit extends Cubit<WriteBranchState> {
  final BranchesRepository branchesRepository;

  WriteBranchCubit({required this.branchesRepository})
      : super(WriteBranchInitial());

  Future<void> create(CreateBranch createBranch) async {
    emit(WritingBranch());
    try {
      final item = await branchesRepository.createBranch(createBranch);
      emit(BranchCreated(item));
    } catch (e) {
      emit(WriteBranchError(e.toString()));
    }
  }

  Future<void> update(String branchId, UpdateBranch branch) async {
    emit(WritingBranch());
    try {
      final item = await branchesRepository.updateBranchById(branchId, branch);
      if (item != null) {
        emit(BranchUpdated(item));
      } else {
        emit(WriteBranchError('Not found'));
      }
    } catch (e) {
      emit(WriteBranchError(e.toString()));
    }
  }

  Future<void> delete(String branchId) async {
    emit(WritingBranch());
    try {
      final item = await branchesRepository.deleteBranchById(branchId);
      if (item != null) {
        emit(BranchDeleted(item));
      } else {
        emit(WriteBranchError('Not found'));
      }
    } catch (e) {
      emit(WriteBranchError(e.toString()));
    }
  }
}

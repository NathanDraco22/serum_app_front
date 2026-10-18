part of 'activation_cubit.dart';

sealed class ActivationState {}

final class ActivationInitial extends ActivationState {}

final class ActivationLoading extends ActivationState {}

final class ActivationSuccess extends ActivationState {
  final Servin servin;
  ActivationSuccess(this.servin);
}

final class ActivationError extends ActivationState {
  final String message;
  ActivationError(this.message);
}

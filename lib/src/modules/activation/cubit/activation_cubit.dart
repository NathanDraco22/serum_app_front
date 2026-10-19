import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'activation_state.dart';

class ActivationCubit extends Cubit<ActivationState> {
  ActivationCubit(this.servinRepository) : super(ActivationInitial());

  final ServinRepository servinRepository;

  Future<void> activate(
    String apiKey,
    String nickname, {
    String? originServerUrl,
  }) async {
    final cleanNickname = nickname.trim();
    final cleanApiKey = apiKey.trim();
    final cleanServerUrl = originServerUrl?.trim();

    if (cleanNickname.isEmpty) {
      emit(ActivationError('Por favor ingresa el alias del negocio.'));
      return;
    }
    if (cleanApiKey.isEmpty) {
      emit(ActivationError('Por favor ingresa la API Key o código de activación.'));
      return;
    }

    emit(ActivationLoading());
    try {
      final servin = await servinRepository.getActiveServin(
        cleanApiKey,
        cleanNickname,
        originServerUrl: (cleanServerUrl != null && cleanServerUrl.isNotEmpty)
            ? cleanServerUrl
            : null,
      );
      emit(ActivationSuccess(servin));
    } catch (error) {
      emit(ActivationError(error.toString().replaceAll('Exception: ', '')));
    }
  }
}

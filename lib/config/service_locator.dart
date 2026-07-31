import 'package:get_it/get_it.dart';
import 'package:serum_business/serum_business.dart';

import '../src/cubits/app_session_cubit/app_session_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Storage
  sl.registerLazySingleton<TokenStorage>(() => HiveTokenStorage());

  // DataSources
  sl.registerLazySingleton<AuthsDataSource>(() => AuthsDataSource());
  sl.registerLazySingleton<UsersDataSource>(() => UsersDataSource());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      dataSource: sl<AuthsDataSource>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  // Cubits (Global App Session)
  sl.registerSingleton<AppSessionCubit>(
    AppSessionCubit(
      authRepository: sl<AuthRepository>(),
      usersDataSource: sl<UsersDataSource>(),
    ),
  );
}

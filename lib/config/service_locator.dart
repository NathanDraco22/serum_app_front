import 'package:serum_business/serum_business.dart';

import '../src/cubits/app_session_cubit/app_session_cubit.dart';
import 'get_it_config.dart';

final sl = getIt;

Future<void> setupServiceLocator() async {
  // Storage
  getIt.registerLazySingleton<TokenStorage>(() => HiveTokenStorage());

  // DataSources
  getIt.registerLazySingleton<AuthsDataSource>(() => AuthsDataSource());
  getIt.registerLazySingleton<UsersDataSource>(() => UsersDataSource());
  getIt.registerLazySingleton<BranchesDataSource>(() => BranchesDataSource());
  getIt.registerLazySingleton<CashShiftsDataSource>(
      () => CashShiftsDataSource());
  getIt.registerLazySingleton<RolesDataSource>(() => RolesDataSource());
  getIt.registerLazySingleton<ReportsDataSource>(() => ReportsDataSource());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      dataSource: getIt<AuthsDataSource>(),
      tokenStorage: getIt<TokenStorage>(),
    ),
  );
  getIt.registerLazySingleton<BranchesRepository>(
    () => BranchesRepository(getIt<BranchesDataSource>()),
  );
  getIt.registerLazySingleton<UsersRepository>(
    () => UsersRepository(getIt<UsersDataSource>()),
  );
  getIt.registerLazySingleton<CashShiftsRepository>(
    () => CashShiftsRepository(getIt<CashShiftsDataSource>()),
  );
  getIt.registerLazySingleton<RolesRepository>(
    () => RolesRepository(getIt<RolesDataSource>()),
  );
  getIt.registerLazySingleton<ReportsRepository>(
    () => ReportsRepository(getIt<ReportsDataSource>()),
  );

  // Cubits (Global App Session)
  getIt.registerSingleton<AppSessionCubit>(
    AppSessionCubit(
      authRepository: getIt<AuthRepository>(),
      branchesRepository: getIt<BranchesRepository>(),
      cashShiftsRepository: getIt<CashShiftsRepository>(),
      usersDataSource: getIt<UsersDataSource>(),
    ),
  );
}

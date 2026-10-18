import 'package:serum_business/serum_business.dart';

import '../src/core/app_config_manager.dart';
import '../src/cubits/app_session_cubit/app_session_cubit.dart';
import '../src/cubits/app_settings/app_settings_cubit.dart';
import 'get_it_config.dart';

final sl = getIt;

Future<void> setupServiceLocator() async {
  // Storage
  getIt.registerLazySingleton<TokenStorage>(() => HiveTokenStorage());
  getIt.registerLazySingleton<AppConfigStore>(() => AppConfigManager());

  // DataSources
  getIt.registerLazySingleton<AppSettingsDataSource>(
      () => AppSettingsDataSource());
  getIt.registerLazySingleton<AuthsDataSource>(() => AuthsDataSource());
  getIt.registerLazySingleton<ServinDataSource>(() => ServinDataSource());
  getIt.registerLazySingleton<UsersDataSource>(() => UsersDataSource());
  getIt.registerLazySingleton<BranchesDataSource>(() => BranchesDataSource());
  getIt.registerLazySingleton<CashShiftsDataSource>(
      () => CashShiftsDataSource());
  getIt.registerLazySingleton<RolesDataSource>(() => RolesDataSource());
  getIt.registerLazySingleton<ReportsDataSource>(() => ReportsDataSource());
  getIt.registerLazySingleton<ApiKeysDataSource>(() => ApiKeysDataSource());
  getIt.registerLazySingleton<LabTestAccountsDataSource>(
      () => LabTestAccountsDataSource());
  getIt.registerLazySingleton<ReceiptsDataSource>(() => ReceiptsDataSource());
  getIt.registerLazySingleton<CashMovementsDataSource>(
      () => CashMovementsDataSource());

  // Repositories
  getIt.registerLazySingleton<AppSettingsRepository>(
    () => AppSettingsRepository(getIt<AppSettingsDataSource>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      dataSource: getIt<AuthsDataSource>(),
      tokenStorage: getIt<TokenStorage>(),
    ),
  );
  getIt.registerLazySingleton<ServinRepository>(
    () => ServinRepository(
      servinDataSource: getIt<ServinDataSource>(),
      appConfigStore: getIt<AppConfigStore>(),
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
  getIt.registerLazySingleton<ApiKeysRepository>(
    () => ApiKeysRepository(getIt<ApiKeysDataSource>()),
  );
  getIt.registerLazySingleton<LabTestAccountsRepository>(
    () => LabTestAccountsRepository(dataSource: getIt<LabTestAccountsDataSource>()),
  );
  getIt.registerLazySingleton<ReceiptsRepository>(
    () => ReceiptsRepository(getIt<ReceiptsDataSource>()),
  );
  getIt.registerLazySingleton<CashMovementsRepository>(
    () => CashMovementsRepository(getIt<CashMovementsDataSource>()),
  );

  // Cubits (Global)
  getIt.registerSingleton<AppSettingsCubit>(
    AppSettingsCubit(getIt<AppSettingsRepository>()),
  );
  getIt.registerSingleton<AppSessionCubit>(
    AppSessionCubit(
      authRepository: getIt<AuthRepository>(),
      branchesRepository: getIt<BranchesRepository>(),
      servinRepository: getIt<ServinRepository>(),
      cashShiftsRepository: getIt<CashShiftsRepository>(),
      usersDataSource: getIt<UsersDataSource>(),
    ),
  );
}

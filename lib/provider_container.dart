import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import 'config/app_serum_config.dart';
import 'config/service_locator.dart';
import 'src/cubits/app_session_cubit/app_session_cubit.dart';
import 'src/cubits/app_settings/app_settings_cubit.dart';
import 'src/cubits/cash_movement_cubit/read_cash_movements_cubit.dart';
import 'src/cubits/cash_movement_cubit/write_cash_movements_cubit.dart';
import 'src/cubits/cash_shift_cubit/read_cash_shifts_cubit.dart';
import 'src/cubits/cash_shift_cubit/write_cash_shifts_cubit.dart';

class ProviderContainer extends StatelessWidget {
  const ProviderContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    SerumClient.initialize(AppSerumConfig());

    final patientsDataSource = PatientsDataSource();
    final doctorsDataSource = DoctorsDataSource();
    final labTestsDataSource = LabTestsDataSource();
    final ordersDataSource = OrdersDataSource();
    final quotationsDataSource = QuotationsDataSource();
    final cashTransactionsDataSource = CashTransactionsDataSource();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppSettingsRepository>.value(
          value: sl<AppSettingsRepository>(),
        ),
        RepositoryProvider<AuthRepository>.value(
          value: sl<AuthRepository>(),
        ),
        RepositoryProvider<ServinRepository>.value(
          value: sl<ServinRepository>(),
        ),
        RepositoryProvider<BranchesRepository>.value(
          value: sl<BranchesRepository>(),
        ),
        RepositoryProvider<UsersRepository>.value(
          value: sl<UsersRepository>(),
        ),
        RepositoryProvider<CashShiftsRepository>.value(
          value: sl<CashShiftsRepository>(),
        ),
        RepositoryProvider<RolesRepository>.value(
          value: sl<RolesRepository>(),
        ),
        RepositoryProvider<ReportsRepository>.value(
          value: sl<ReportsRepository>(),
        ),
        RepositoryProvider<ApiKeysRepository>.value(
          value: sl<ApiKeysRepository>(),
        ),
        RepositoryProvider<LabTestAccountsRepository>.value(
          value: sl<LabTestAccountsRepository>(),
        ),
        RepositoryProvider(
          create: (_) => PatientsRepository(patientsDataSource),
        ),
        RepositoryProvider(
          create: (_) => DoctorsRepository(doctorsDataSource),
        ),
        RepositoryProvider(
          create: (_) => LabTestsRepository(labTestsDataSource),
        ),
        RepositoryProvider(
          create: (_) => OrdersRepository(ordersDataSource),
        ),
        RepositoryProvider(
          create: (_) => QuotationsRepository(quotationsDataSource),
        ),
        RepositoryProvider<ReceiptsRepository>.value(
          value: sl<ReceiptsRepository>(),
        ),
        RepositoryProvider<CashMovementsRepository>.value(
          value: sl<CashMovementsRepository>(),
        ),
        RepositoryProvider<ImportsRepository>.value(
          value: sl<ImportsRepository>(),
        ),
        RepositoryProvider(
          create: (_) => CashTransactionsRepository(cashTransactionsDataSource),
        ),
      ],
      child: GlobalCubitProvider(
        child: child,
      ),
    );
  }
}

class GlobalCubitProvider extends StatelessWidget {
  const GlobalCubitProvider({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsCubit>.value(
          value: sl<AppSettingsCubit>(),
        ),
        BlocProvider<AppSessionCubit>.value(
          value: sl<AppSessionCubit>(),
        ),
      ],
      child: BlocBuilder<AppSessionCubit, AppSessionState>(
        buildWhen: (previous, current) =>
            previous.currentBranch?.id != current.currentBranch?.id,
        builder: (context, sessionState) {
          final branchId = sessionState.currentBranch?.id ?? 'none';
          return MultiBlocProvider(
            key: ValueKey('branch_scope_$branchId'),
            providers: [
              BlocProvider<ReadCashShiftCubit>(
                create: (ctx) => ReadCashShiftCubit(
                  cashShiftsRepository: ctx.read<CashShiftsRepository>(),
                ),
              ),
              BlocProvider<WriteCashShiftCubit>(
                create: (ctx) => WriteCashShiftCubit(
                  cashShiftsRepository: ctx.read<CashShiftsRepository>(),
                ),
              ),
              BlocProvider<ReadCashMovementCubit>(
                create: (ctx) => ReadCashMovementCubit(
                  cashMovementsRepository: ctx.read<CashMovementsRepository>(),
                ),
              ),
              BlocProvider<WriteCashMovementCubit>(
                create: (ctx) => WriteCashMovementCubit(
                  cashMovementsRepository: ctx.read<CashMovementsRepository>(),
                ),
              ),
            ],
            child: child,
          );
        },
      ),
    );
  }
}

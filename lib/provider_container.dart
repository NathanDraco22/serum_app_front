import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import 'config/app_serum_config.dart';
import 'config/service_locator.dart';
import 'src/cubits/app_session_cubit/app_session_cubit.dart';
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
        RepositoryProvider<AuthRepository>.value(
          value: sl<AuthRepository>(),
        ),
        RepositoryProvider<BranchesRepository>.value(
          value: sl<BranchesRepository>(),
        ),
        RepositoryProvider<CashShiftsRepository>.value(
          value: sl<CashShiftsRepository>(),
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
        BlocProvider<AppSessionCubit>.value(
          value: sl<AppSessionCubit>(),
        ),
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
      ],
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'src/cubits/app_session_cubit/app_session_cubit.dart';

class AppClientConfig implements SerumClientConfig {
  static const _baseUrl = String.fromEnvironment("SERVER_URL");

  @override
  String get baseUrl {
    return _baseUrl;
  }

  @override
  String get authToken => '';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SerumClient.initialize(AppClientConfig());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppSessionCubit _sessionCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _sessionCubit = AppSessionCubit();
    _router = AppRouter.createRouter(_sessionCubit);
  }

  @override
  void dispose() {
    _sessionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PatientsRepository>(
          create: (_) => PatientsRepository(PatientsDataSource()),
        ),
        RepositoryProvider<DoctorsRepository>(
          create: (_) => DoctorsRepository(DoctorsDataSource()),
        ),
        RepositoryProvider<ExamsRepository>(
          create: (_) => ExamsRepository(ExamsDataSource()),
        ),
        RepositoryProvider<LabTestsRepository>(
          create: (_) => LabTestsRepository(LabTestsDataSource()),
        ),
        RepositoryProvider<OrdersRepository>(
          create: (_) => OrdersRepository(OrdersDataSource()),
        ),
        RepositoryProvider<QuotationsRepository>(
          create: (_) => QuotationsRepository(QuotationsDataSource()),
        ),
        RepositoryProvider<CashRegistersRepository>(
          create: (_) => CashRegistersRepository(CashRegistersDataSource()),
        ),
        RepositoryProvider<CashTransactionsRepository>(
          create: (_) => CashTransactionsRepository(CashTransactionsDataSource()),
        ),
      ],
      child: BlocProvider<AppSessionCubit>.value(
        value: _sessionCubit,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          title: 'Serum LIS',
          routerConfig: _router,
        ),
      ),
    );
  }
}

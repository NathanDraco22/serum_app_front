import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'config/service_locator.dart';
import 'src/cubits/app_session_cubit/app_session_cubit.dart';

class AppClientConfig implements SerumClientConfig {
  static const _baseUrl = String.fromEnvironment("SERVER_URL");
  String _token = '';

  @override
  String get baseUrl => _baseUrl;

  @override
  String get authToken => _token;

  @override
  set authToken(String token) {
    _token = token;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SerumClient.initialize(AppClientConfig());
  await setupServiceLocator();
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
    _sessionCubit = sl<AppSessionCubit>();
    _router = AppRouter.createRouter(_sessionCubit);
  }


  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: sl<AuthRepository>(),
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import 'config/app_theme.dart';
import 'config/app_router.dart';

class AppClientConfig implements SerumClientConfig {
  @override
  String get baseUrl => 'http://localhost:8000';

  @override
  String get authToken => '';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SerumClient.initialize(AppClientConfig());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        title: 'Serum LIS',
        routerConfig: AppRouter.router,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'config/scroll_behavior.dart';
import 'config/service_locator.dart';
import 'material_app_builder.dart';
import 'provider_container.dart';
import 'src/cubits/app_session_cubit/app_session_cubit.dart';
import 'src/tools/exports/pdf/pdf_font_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  await setupServiceLocator();
  await PdfFontHelper.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderContainer(
      child: AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  GoRouter? _router;
  String? _lastBranchId;

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  void _ensureRouter(String? branchId) {
    if (_router == null || _lastBranchId != branchId) {
      final isBranchSwitch = _lastBranchId != null && _lastBranchId != branchId;
      _lastBranchId = branchId;
      _router?.dispose();
      _router = AppRouter.createRouter(
        sl<AppSessionCubit>(),
        initialLocation: isBranchSwitch ? AppRouter.lastKnownLocation : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<AppSessionCubit>().state;
    final branchId = sessionState.currentBranch?.id;
    _ensureRouter(branchId);

    return MaterialApp.router(
      key: ValueKey('serum_app_${branchId ?? "none"}'),
      title: 'Serum App',
      routerConfig: _router!,
      builder: materialAppBuilder,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      scrollBehavior: AlwaysStretchScrollBehavior(),
      darkTheme: AppTheme.darkTheme,
    );
  }
}

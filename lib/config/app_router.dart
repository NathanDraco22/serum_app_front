import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../src/cubits/app_session_cubit/app_session_cubit.dart';
import '../src/modules/splash/view/splash_screen.dart';
import '../src/modules/auth/view/login_screen.dart';
import '../src/modules/home_menu/home_menus_view.dart';
import '../src/modules/dashboard/view/dashboard_screen.dart';
import '../src/modules/patient/view/patient_screen.dart';
import '../src/modules/doctor/view/doctor_screen.dart';
import '../src/modules/lab_test/view/lab_test_screen.dart';
import '../src/modules/order/view/order_screen.dart';
import '../src/modules/order/view/create_order_screen.dart';
import '../src/modules/quotation/view/quotation_screen.dart';
import '../src/modules/quotation/view/create_quotation_screen.dart';
import '../src/modules/cash_shift/view/cash_shifts_screen.dart';
import '../src/modules/cash_transaction/view/cash_transaction_screen.dart';
import '../src/modules/administration/view/administration_screen.dart';
import '../src/modules/branch/view/branch_screen.dart';
import '../src/modules/user/view/user_screen.dart';
import '../src/modules/role/view/role_screen.dart';
import '../src/modules/report/view/reports_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  // Constantes de rutas
  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/';
  static const String patients = '/patients';
  static const String doctors = '/doctors';
  static const String labTests = '/lab-tests';
  static const String orders = '/orders';
  static const String createOrder = '/orders/new';
  static const String quotations = '/quotations';
  static const String createQuotation = '/quotations/new';
  static const String cashShifts = '/cash-shifts';
  static const String cashTransactions = '/cash-transactions';
  static const String reports = '/reports';
  static const String administration = '/admin';
  static const String adminBranches = '/admin/branches';
  static const String adminUsers = '/admin/users';
  static const String adminRoles = '/admin/roles';

  // Navigator keys para cada branch
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _dashboardNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'dashboard');
  static final _patientsNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'patients');
  static final _doctorsNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'doctors');
  static final _labTestsNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'labTests');
  static final _ordersNavKey = GlobalKey<NavigatorState>(debugLabel: 'orders');
  static final _quotationsNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'quotations');
  static final _cashShiftsNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'cashShifts');
  static final _cashTransactionsNavKey =
      GlobalKey<NavigatorState>(debugLabel: 'cashTransactions');
  static final _reportsNavKey = GlobalKey<NavigatorState>(debugLabel: 'reports');
  static final _adminNavKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

  static GoRouter createRouter(AppSessionCubit sessionCubit) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: splash,
      refreshListenable: GoRouterRefreshStream(sessionCubit.stream),
      redirect: (context, state) {
        final sessionState = sessionCubit.state;

        final isInitial = sessionState.status == AppSessionStatus.initial ||
            sessionState.status == AppSessionStatus.authenticating;
        final isAuthenticated = sessionState.isAuthenticated;

        final isSplashing = state.matchedLocation == splash;
        final isLoggingIn = state.matchedLocation == login;

        // 1. Inicialización en progreso -> Redirigir a /splash
        if (isInitial) {
          return isSplashing ? null : splash;
        }

        // 2. No autenticado -> Redirigir a /login
        if (!isAuthenticated) {
          return isLoggingIn ? null : login;
        }

        // 3. Autenticado -> Redirigir a Dashboard si intenta estar en /splash o /login
        if (isSplashing || isLoggingIn) {
          return dashboard;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: createOrder,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const CreateOrderScreen(),
        ),
        GoRoute(
          path: createQuotation,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const CreateQuotationScreen(),
        ),
        GoRoute(
          path: adminBranches,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const BranchesScreen(),
        ),
        GoRoute(
          path: adminUsers,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: adminRoles,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const RoleScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeMenusScreen(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Inicio / Dashboard
            StatefulShellBranch(
              navigatorKey: _dashboardNavKey,
              routes: [
                GoRoute(
                  path: dashboard,
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            // Branch 1: Pacientes
            StatefulShellBranch(
              navigatorKey: _patientsNavKey,
              routes: [
                GoRoute(
                  path: patients,
                  builder: (context, state) => const PatientsScreen(),
                ),
              ],
            ),
            // Branch 2: Médicos
            StatefulShellBranch(
              navigatorKey: _doctorsNavKey,
              routes: [
                GoRoute(
                  path: doctors,
                  builder: (context, state) => const DoctorsScreen(),
                ),
              ],
            ),
            // Branch 3: Pruebas y Packs de Laboratorio
            StatefulShellBranch(
              navigatorKey: _labTestsNavKey,
              routes: [
                GoRoute(
                  path: labTests,
                  builder: (context, state) => const LabTestsScreen(),
                ),
              ],
            ),
            // Branch 4: Órdenes Clínicas
            StatefulShellBranch(
              navigatorKey: _ordersNavKey,
              routes: [
                GoRoute(
                  path: orders,
                  builder: (context, state) => const OrdersScreen(),
                ),
              ],
            ),
            // Branch 5: Cotizaciones
            StatefulShellBranch(
              navigatorKey: _quotationsNavKey,
              routes: [
                GoRoute(
                  path: quotations,
                  builder: (context, state) => const QuotationsScreen(),
                ),
              ],
            ),
            // Branch 6: Turnos de Caja
            StatefulShellBranch(
              navigatorKey: _cashShiftsNavKey,
              routes: [
                GoRoute(
                  path: cashShifts,
                  builder: (context, state) => const CashShiftsScreen(),
                ),
                GoRoute(
                  path: '/cash-registers',
                  redirect: (context, state) => cashShifts,
                ),
              ],
            ),
            // Branch 7: Transacciones de Caja
            StatefulShellBranch(
              navigatorKey: _cashTransactionsNavKey,
              routes: [
                GoRoute(
                  path: cashTransactions,
                  builder: (context, state) => const CashTransactionsScreen(),
                ),
              ],
            ),
            // Branch 8: Reportes Analíticos
            StatefulShellBranch(
              navigatorKey: _reportsNavKey,
              routes: [
                GoRoute(
                  path: reports,
                  builder: (context, state) => const ReportsScreen(),
                ),
              ],
            ),
            // Branch 9: Administración
            StatefulShellBranch(
              navigatorKey: _adminNavKey,
              routes: [
                GoRoute(
                  path: administration,
                  builder: (context, state) => const AdministrationScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

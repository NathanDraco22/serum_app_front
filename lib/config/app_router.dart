import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../src/cubits/app_session_cubit/app_session_cubit.dart';
import '../src/modules/splash/view/splash_screen.dart';
import '../src/modules/activation/view/activation_screen.dart';
import '../src/modules/inactive/view/inactive_screen.dart';
import '../src/modules/auth/view/login_screen.dart';
import '../src/modules/home_menu/home_menus_view.dart';
import '../src/modules/dashboard/view/dashboard_screen.dart';
import '../src/modules/patient/view/patient_screen.dart';
import '../src/modules/patient/view/patient_orders_history_screen.dart';
import '../src/modules/doctor/view/doctor_screen.dart';
import '../src/modules/lab_test/view/lab_test_screen.dart';
import '../src/modules/order/view/order_screen.dart';
import '../src/modules/order/view/create_order_screen.dart';
import '../src/modules/quotation/view/quotation_screen.dart';
import '../src/modules/quotation/view/create_quotation_screen.dart';
import '../src/modules/cash_shift/view/cash_shifts_screen.dart';
import '../src/modules/cash_transaction/view/cash_transaction_screen.dart';
import '../src/modules/receipt/view/receipts_screen.dart';
import '../src/modules/administration/view/administration_screen.dart';
import '../src/modules/administration/view/app_settings/app_settings_screen.dart';
import '../src/modules/branch/view/branch_screen.dart';
import '../src/modules/user/view/user_screen.dart';
import '../src/modules/role/view/role_screen.dart';
import '../src/modules/report/view/reports_screen.dart';
import '../src/modules/api_keys/view/api_keys_screen.dart';
import '../src/modules/imports/view/imports_screen.dart';

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
  static const String activation = '/activation';
  static const String inactive = '/inactive';
  static const String login = '/login';
  static const String dashboard = '/';
  static const String patients = '/patients';
  static const String patientOrders = '/patients/:patientId/orders';
  static const String doctors = '/doctors';
  static const String labTests = '/lab-tests';
  static const String orders = '/orders';
  static const String createOrder = '/orders/new';
  static const String quotations = '/quotations';
  static const String createQuotation = '/quotations/new';
  static const String cashShifts = '/cash-shifts';
  static const String cashTransactions = '/cash-transactions';
  static const String receipts = '/receipts';
  static const String reports = '/reports';
  static const String administration = '/admin';
  static const String adminBranches = '/admin/branches';
  static const String adminUsers = '/admin/users';
  static const String adminRoles = '/admin/roles';
  static const String adminApiKeys = '/admin/api-keys';
  static const String adminAppSettings = '/admin/settings';
  static const String adminImports = '/admin/imports';

  static String? _lastKnownLocation;
  static String? get lastKnownLocation => _lastKnownLocation;
  static void setLastKnownLocation(String? location) =>
      _lastKnownLocation = location;

  static GoRouter createRouter(
    AppSessionCubit sessionCubit, {
    String? initialLocation,
  }) {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final dashboardNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'dashboard');
    final patientsNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'patients');
    final doctorsNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'doctors');
    final labTestsNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'labTests');
    final ordersNavKey = GlobalKey<NavigatorState>(debugLabel: 'orders');
    final quotationsNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'quotations');
    final cashShiftsNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'cashShifts');
    final cashTransactionsNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'cashTransactions');
    final receiptsNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'receipts');
    final reportsNavKey =
        GlobalKey<NavigatorState>(debugLabel: 'reports');
    final adminNavKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation ?? splash,
      refreshListenable: GoRouterRefreshStream(sessionCubit.stream),
      redirect: (context, state) {
        final sessionState = sessionCubit.state;

        final isInitial = sessionState.status == AppSessionStatus.initial ||
            sessionState.status == AppSessionStatus.authenticating;
        final isUnactivated =
            sessionState.status == AppSessionStatus.unactivated;
        final isInstanceInactive =
            sessionState.status == AppSessionStatus.instanceInactive;
        final isAuthenticated = sessionState.isAuthenticated;

        final isSplashing = state.matchedLocation == splash;
        final isActivating = state.matchedLocation == activation;
        final isInactive = state.matchedLocation == inactive;
        final isLoggingIn = state.matchedLocation == login;

        // 1. Inicialización en progreso -> Redirigir a /splash
        if (isInitial) {
          return isSplashing ? null : splash;
        }

        // 2. Terminal sin activar (no hay Servin configurado) -> Redirigir a /activation
        if (isUnactivated) {
          return isActivating ? null : activation;
        }

        // 3. Terminal con instancia desactivada/bloqueada -> Redirigir a /inactive
        if (isInstanceInactive) {
          return isInactive ? null : inactive;
        }

        // 4. Instancia activa pero usuario no autenticado -> Redirigir a /login
        if (!isAuthenticated) {
          _lastKnownLocation = null;
          return isLoggingIn ? null : login;
        }

        // Registrar la última ubicación operativa para cambios de sucursal
        final currentLoc = state.matchedLocation;
        if (currentLoc != splash &&
            currentLoc != login &&
            currentLoc != activation &&
            currentLoc != inactive) {
          if (currentLoc == createOrder) {
            _lastKnownLocation = orders;
          } else if (currentLoc == createQuotation) {
            _lastKnownLocation = quotations;
          } else {
            _lastKnownLocation = currentLoc;
          }
        }

        // 5. Autenticado -> Redirigir a Dashboard si intenta acceder a pantallas de onboarding o auth
        if (isSplashing || isLoggingIn || isActivating || isInactive) {
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
          path: activation,
          builder: (context, state) => const ActivationScreen(),
        ),
        GoRoute(
          path: inactive,
          builder: (context, state) => const InactiveScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: createOrder,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CreateOrderScreen(),
        ),
        GoRoute(
          path: createQuotation,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CreateQuotationScreen(),
        ),
        GoRoute(
          path: patientOrders,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final patientId = state.pathParameters['patientId'] ?? '';
            final patient = state.extra as PatientInDb?;
            return PatientOrdersHistoryScreen(
              patientId: patientId,
              patient: patient,
            );
          },
        ),
        GoRoute(
          path: adminBranches,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const BranchesScreen(),
        ),
        GoRoute(
          path: adminUsers,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: adminRoles,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const RoleScreen(),
        ),
        GoRoute(
          path: adminApiKeys,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ApiKeysScreen(),
        ),
        GoRoute(
          path: adminAppSettings,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const AppSettingsScreen(),
        ),
        GoRoute(
          path: adminImports,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ImportsScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeMenusScreen(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Inicio / Dashboard
            StatefulShellBranch(
              navigatorKey: dashboardNavKey,
              routes: [
                GoRoute(
                  path: dashboard,
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            // Branch 1: Pacientes
            StatefulShellBranch(
              navigatorKey: patientsNavKey,
              routes: [
                GoRoute(
                  path: patients,
                  builder: (context, state) => const PatientsScreen(),
                ),
              ],
            ),
            // Branch 2: Médicos
            StatefulShellBranch(
              navigatorKey: doctorsNavKey,
              routes: [
                GoRoute(
                  path: doctors,
                  builder: (context, state) => const DoctorsScreen(),
                ),
              ],
            ),
            // Branch 3: Pruebas y Packs de Laboratorio
            StatefulShellBranch(
              navigatorKey: labTestsNavKey,
              routes: [
                GoRoute(
                  path: labTests,
                  builder: (context, state) => const LabTestsScreen(),
                ),
              ],
            ),
            // Branch 4: Órdenes Clínicas
            StatefulShellBranch(
              navigatorKey: ordersNavKey,
              routes: [
                GoRoute(
                  path: orders,
                  builder: (context, state) => const OrdersScreen(),
                ),
              ],
            ),
            // Branch 5: Cotizaciones
            StatefulShellBranch(
              navigatorKey: quotationsNavKey,
              routes: [
                GoRoute(
                  path: quotations,
                  builder: (context, state) => const QuotationsScreen(),
                ),
              ],
            ),
            // Branch 6: Turnos de Caja
            StatefulShellBranch(
              navigatorKey: cashShiftsNavKey,
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
              navigatorKey: cashTransactionsNavKey,
              routes: [
                GoRoute(
                  path: cashTransactions,
                  builder: (context, state) => const CashTransactionsScreen(),
                ),
              ],
            ),
            // Branch 8: Recibos de Caja
            StatefulShellBranch(
              navigatorKey: receiptsNavKey,
              routes: [
                GoRoute(
                  path: receipts,
                  builder: (context, state) => const ReceiptsScreen(),
                ),
              ],
            ),
            // Branch 9: Reportes Analíticos
            StatefulShellBranch(
              navigatorKey: reportsNavKey,
              routes: [
                GoRoute(
                  path: reports,
                  builder: (context, state) => const ReportsScreen(),
                ),
              ],
            ),
            // Branch 10: Administración
            StatefulShellBranch(
              navigatorKey: adminNavKey,
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

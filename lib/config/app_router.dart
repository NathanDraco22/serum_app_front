import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../src/modules/home_menu/home_menus_view.dart';
import '../src/modules/dashboard/view/dashboard_screen.dart';
import '../src/modules/patient/view/patient_screen.dart';
import '../src/modules/doctor/view/doctor_screen.dart';
import '../src/modules/exam/view/exam_screen.dart';
import '../src/modules/lab_test/view/lab_test_screen.dart';
import '../src/modules/order/view/order_screen.dart';
import '../src/modules/quotation/view/quotation_screen.dart';
import '../src/modules/cash_register/view/cash_register_screen.dart';
import '../src/modules/cash_transaction/view/cash_transaction_screen.dart';

class AppRouter {
  AppRouter._();

  // Constantes de rutas
  static const String dashboard = '/';
  static const String patients = '/patients';
  static const String doctors = '/doctors';
  static const String exams = '/exams';
  static const String labTests = '/lab-tests';
  static const String orders = '/orders';
  static const String quotations = '/quotations';
  static const String cashRegisters = '/cash-registers';
  static const String cashTransactions = '/cash-transactions';

  // Navigator keys para cada branch
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _dashboardNavKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
  static final _patientsNavKey = GlobalKey<NavigatorState>(debugLabel: 'patients');
  static final _doctorsNavKey = GlobalKey<NavigatorState>(debugLabel: 'doctors');
  static final _examsNavKey = GlobalKey<NavigatorState>(debugLabel: 'exams');
  static final _labTestsNavKey = GlobalKey<NavigatorState>(debugLabel: 'labTests');
  static final _ordersNavKey = GlobalKey<NavigatorState>(debugLabel: 'orders');
  static final _quotationsNavKey = GlobalKey<NavigatorState>(debugLabel: 'quotations');
  static final _cashRegistersNavKey = GlobalKey<NavigatorState>(debugLabel: 'cashRegisters');
  static final _cashTransactionsNavKey = GlobalKey<NavigatorState>(debugLabel: 'cashTransactions');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: dashboard,
    routes: [
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
          // Branch 3: Exámenes
          StatefulShellBranch(
            navigatorKey: _examsNavKey,
            routes: [
              GoRoute(
                path: exams,
                builder: (context, state) => const ExamsScreen(),
              ),
            ],
          ),
          // Branch 4: Pruebas de Laboratorio
          StatefulShellBranch(
            navigatorKey: _labTestsNavKey,
            routes: [
              GoRoute(
                path: labTests,
                builder: (context, state) => const LabTestsScreen(),
              ),
            ],
          ),
          // Branch 5: Órdenes Clínicas
          StatefulShellBranch(
            navigatorKey: _ordersNavKey,
            routes: [
              GoRoute(
                path: orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          // Branch 6: Cotizaciones
          StatefulShellBranch(
            navigatorKey: _quotationsNavKey,
            routes: [
              GoRoute(
                path: quotations,
                builder: (context, state) => const QuotationsScreen(),
              ),
            ],
          ),
          // Branch 7: Cajas Registradoras
          StatefulShellBranch(
            navigatorKey: _cashRegistersNavKey,
            routes: [
              GoRoute(
                path: cashRegisters,
                builder: (context, state) => const CashRegistersScreen(),
              ),
            ],
          ),
          // Branch 8: Transacciones de Caja
          StatefulShellBranch(
            navigatorKey: _cashTransactionsNavKey,
            routes: [
              GoRoute(
                path: cashTransactions,
                builder: (context, state) => const CashTransactionsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/app_session_cubit/app_session_cubit.dart';

/// Firma del constructor que recibe el contexto y el indicador booleano de si el
/// usuario cuenta con el nivel o permisos requeridos.
typedef PermissionGateBuilder = Widget Function(
  BuildContext context,
  bool hasPermission,
);

/// Modos de evaluación para comparar el nivel del usuario respecto al nivel solicitado.
enum LevelGateMode {
  /// Requiere al menos el nivel especificado (userLevel >= level). Modo jerárquico por defecto.
  atLeast,

  /// Requiere exactamente el nivel especificado (userLevel == level).
  exact,

  /// Requiere como máximo el nivel especificado (userLevel <= level).
  atMost,
}

/// Constantes semánticas para los niveles de acceso del sistema.
abstract final class AccessLevels {
  /// Sin sesión iniciada o nivel nulo.
  static const int guest = 0;

  /// Nivel 1: Modo solo lectura y consultas básicas.
  static const int readonly = 1;

  /// Nivel 2: Recepción y consultas operativas asistidas.
  static const int assistant = 2;

  /// Nivel 3: Operador de caja y POS, registro de pacientes y órdenes.
  static const int operator = 3;

  /// Nivel 4: Supervisor de sucursal, autorizaciones y auditorías.
  static const int supervisor = 4;

  /// Nivel 5: Administrador global con control total.
  static const int admin = 5;
}

/// Widget protector de control de acceso basado en niveles jerárquicos.
///
/// Evalúa el nivel de acceso del usuario actual en [AppSessionCubit] y delega
/// la construcción visual a un método [builder], pasándole el resultado booleano.
/// Esto permite tanto ocultar componentes como renderizarlos en estado deshabilitado.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    required this.level,
    required this.builder,
    this.mode = LevelGateMode.atLeast,
    this.allowedLevels,
    this.width,
    this.height,
  });

  /// Nivel de acceso requerido (por ejemplo, [AccessLevels.operator] o 3).
  final int level;

  /// Función constructora que recibe el contexto y [hasPermission].
  final PermissionGateBuilder builder;

  /// Modo de comparación para el nivel requerido. Por defecto [LevelGateMode.atLeast].
  final LevelGateMode mode;

  /// Lista opcional de niveles permitidos específicos. Si se proporciona,
  /// se evalúa si el nivel del usuario pertenece a esta lista ignorando [level] y [mode].
  final List<int>? allowedLevels;

  /// Ancho opcional para envolver el resultado dentro de un [SizedBox].
  final double? width;

  /// Alto opcional para envolver el resultado dentro de un [SizedBox].
  final double? height;

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<AppSessionCubit>().state;
    final currentUser = sessionState.currentUser;

    final hasPermission = _evaluateAccess(
      userLevel: currentUser?.accessLevel ?? AccessLevels.guest,
      isActive: currentUser?.isActive ?? false,
      isDeleted: currentUser?.isDeleted ?? false,
    );

    final result = builder(context, hasPermission);

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: result,
      );
    }

    return result;
  }

  bool _evaluateAccess({
    required int userLevel,
    required bool isActive,
    required bool isDeleted,
  }) {
    if (!isActive || isDeleted || userLevel <= AccessLevels.guest) {
      return false;
    }

    if (allowedLevels != null) {
      return allowedLevels!.contains(userLevel);
    }

    return switch (mode) {
      LevelGateMode.atLeast => userLevel >= level,
      LevelGateMode.exact => userLevel == level,
      LevelGateMode.atMost => userLevel <= level,
    };
  }
}

/// Extensiones de conveniencia sobre [BuildContext] para evaluar niveles de acceso
/// de forma reactiva en cualquier punto del árbol de widgets.
extension AccessContextExtension on BuildContext {
  /// Retorna el nivel de acceso del usuario actual o 0 si no hay sesión activa.
  int get userAccessLevel {
    final user = watch<AppSessionCubit>().state.currentUser;
    if (user == null || !user.isActive || user.isDeleted) {
      return AccessLevels.guest;
    }
    return user.accessLevel;
  }

  /// Verifica si el usuario actual cumple al menos con el nivel de acceso indicado.
  bool hasAccessLevel(int minLevel) => userAccessLevel >= minLevel;
}

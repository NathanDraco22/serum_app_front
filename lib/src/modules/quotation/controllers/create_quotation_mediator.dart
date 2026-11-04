import 'package:flutter/widgets.dart';
import 'create_quotation_view_controller.dart';

/// Mediator para la pantalla de Creación de Cotizaciones.
///
/// Siguiendo la arquitectura Mediator del estándar OKF:
/// - Es un `InheritedWidget` mudo (`updateShouldNotify: false`) que expone el [CreateQuotationViewController].
/// - Elimina el prop-drilling hacia [QuotationCartSection] y demás widgets hijos.
/// - Permite que los widgets se suscriban quirúrgicamente utilizando [ListenableBuilder].
class CreateQuotationMediator extends InheritedWidget {
  const CreateQuotationMediator({
    super.key,
    required super.child,
    required this.viewController,
  });

  final CreateQuotationViewController viewController;

  /// Obtiene la instancia del mediador más cercano en el árbol de widgets.
  static CreateQuotationMediator of(BuildContext context) {
    final mediator = context.dependOnInheritedWidgetOfExactType<CreateQuotationMediator>();
    assert(mediator != null, 'No CreateQuotationMediator found in context');
    return mediator!;
  }

  /// Obtiene el [CreateQuotationViewController] si el mediador existe en el contexto, o `null`.
  static CreateQuotationViewController? maybeControllerOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CreateQuotationMediator>()?.viewController;
  }

  /// Obtiene directamente el [CreateQuotationViewController] activo del contexto.
  static CreateQuotationViewController controllerOf(BuildContext context) {
    return of(context).viewController;
  }

  @override
  bool updateShouldNotify(CreateQuotationMediator oldWidget) => false;
}

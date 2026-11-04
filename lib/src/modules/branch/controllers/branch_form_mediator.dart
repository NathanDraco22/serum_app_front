import 'package:flutter/widgets.dart';

import 'branch_form_view_controller.dart';

/// Mediator para el diálogo de gestión de sucursal (`BranchFormDialog`).
/// Expone el [BranchFormViewController] a lo largo del árbol de widgets mediante un
/// [InheritedWidget] mudo (updateShouldNotify: false). Las secciones visuales se suscriben
/// granularmente usando [ListenableBuilder] para prevenir redibujados globales innecesarios.
class BranchFormMediator extends InheritedWidget {
  const BranchFormMediator({
    super.key,
    required super.child,
    required this.viewController,
  });

  final BranchFormViewController viewController;

  static BranchFormMediator of(BuildContext context) {
    final mediator =
        context.dependOnInheritedWidgetOfExactType<BranchFormMediator>();
    assert(mediator != null, 'No BranchFormMediator found in context');
    return mediator!;
  }

  static BranchFormViewController? maybeControllerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BranchFormMediator>()
        ?.viewController;
  }

  static BranchFormViewController controllerOf(BuildContext context) {
    return of(context).viewController;
  }

  @override
  bool updateShouldNotify(BranchFormMediator oldWidget) => false;
}

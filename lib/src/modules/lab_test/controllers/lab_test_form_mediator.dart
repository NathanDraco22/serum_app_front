import 'package:flutter/widgets.dart';
import 'lab_test_form_view_controller.dart';

/// Mediator para el módulo de estudios clínicos y perfiles/packs.
/// Expone el [LabTestFormViewController] a través del árbol de widgets mediante un
/// [InheritedWidget] mudo (updateShouldNotify: false). Las secciones visuales se suscriben
/// granularmente usando [ListenableBuilder].
class LabTestFormMediator extends InheritedWidget {
  const LabTestFormMediator({
    super.key,
    required super.child,
    required this.viewController,
  });

  final LabTestFormViewController viewController;

  static LabTestFormMediator of(BuildContext context) {
    final mediator = context.dependOnInheritedWidgetOfExactType<LabTestFormMediator>();
    assert(mediator != null, 'No LabTestFormMediator found in context');
    return mediator!;
  }

  static LabTestFormViewController? maybeControllerOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LabTestFormMediator>()?.viewController;
  }

  static LabTestFormViewController controllerOf(BuildContext context) {
    return of(context).viewController;
  }

  @override
  bool updateShouldNotify(LabTestFormMediator oldWidget) => false;
}

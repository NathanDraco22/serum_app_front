import 'package:flutter/widgets.dart';
import 'create_order_view_controller.dart';

class CreateOrderMediator extends InheritedWidget {
  const CreateOrderMediator({
    super.key,
    required super.child,
    required this.viewController,
  });

  final CreateOrderViewController viewController;

  static CreateOrderMediator of(BuildContext context) {
    final mediator = context.dependOnInheritedWidgetOfExactType<CreateOrderMediator>();
    assert(mediator != null, 'No CreateOrderMediator found in context');
    return mediator!;
  }

  static CreateOrderViewController? maybeControllerOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CreateOrderMediator>()?.viewController;
  }

  static CreateOrderViewController controllerOf(BuildContext context) {
    return of(context).viewController;
  }

  @override
  bool updateShouldNotify(CreateOrderMediator oldWidget) => false;
}

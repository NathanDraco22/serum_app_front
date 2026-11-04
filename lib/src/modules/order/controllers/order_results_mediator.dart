import 'package:flutter/widgets.dart';
import 'order_results_view_controller.dart';

class OrderResultsMediator extends InheritedWidget {
  const OrderResultsMediator({
    super.key,
    required super.child,
    required this.viewController,
  });

  final OrderResultsViewController viewController;

  static OrderResultsMediator of(BuildContext context) {
    final mediator = context.dependOnInheritedWidgetOfExactType<OrderResultsMediator>();
    assert(mediator != null, 'No OrderResultsMediator found in context');
    return mediator!;
  }

  static OrderResultsViewController? maybeControllerOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OrderResultsMediator>()?.viewController;
  }

  static OrderResultsViewController controllerOf(BuildContext context) {
    return of(context).viewController;
  }

  @override
  bool updateShouldNotify(OrderResultsMediator oldWidget) => false;
}

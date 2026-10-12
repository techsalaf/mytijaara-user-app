import 'package:flutter/widgets.dart';
import 'package:sixam_mart/helper/keyboard_helper.dart';

class KeyboardDismissRouteObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _dismissFor(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _dismissFor(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _dismissFor(oldRoute);
  }

  void _dismissFor(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    KeyboardHelper.dismissAfterFrame();
  }
}
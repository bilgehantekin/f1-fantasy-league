import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

void safeBack(BuildContext context, {String fallbackLocation = '/calendar'}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(fallbackLocation);
}

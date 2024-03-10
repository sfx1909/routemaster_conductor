import 'package:example/src/routes.g.dart';
import 'package:flutter/widgets.dart';
import 'package:routemaster/routemaster.dart';

RouteSettings tabTemplate(RouteData routeData, Widget child) {
  return TabPage(child: child, paths: [
    tabsOneRoute.path,
    tabsTwoRoute.path,
  ]);
}

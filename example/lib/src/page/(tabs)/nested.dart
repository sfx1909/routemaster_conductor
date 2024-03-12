import 'package:flutter/widgets.dart';
import 'package:routemaster/routemaster.dart';

import '../../routes.g.dart';

RouteSettings tab(RouteData routeData, Widget child) {
  return TabPage(child: child, paths: [
    tabsOneRoute.path,
    tabsTwoRoute.path,
  ]);
}

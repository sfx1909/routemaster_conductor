import 'package:flutter/widgets.dart';
import 'package:routemaster/routemaster.dart';

RouteSettings redirectTemplate(RouteData routeData, Widget _) {
  return const Redirect('/');
}

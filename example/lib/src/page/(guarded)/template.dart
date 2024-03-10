import 'dart:math';

import 'package:example/src/page/(guarded)/page.dart';
import 'package:example/src/page/(guarded)/some/page.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

RouteSettings guardTemplate(RouteData routeData, Widget _) {
  final isGaurded = Random().nextBool();
  return isGaurded
      ? const MaterialPage(child: GuardedPage())
      : const MaterialPage(child: UnguardedPage());
}

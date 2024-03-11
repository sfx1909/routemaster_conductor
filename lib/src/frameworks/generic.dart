import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:routemaster_conductor/src/builder.dart';

class GenericRouteBuilder extends RouteBuilder {
  GenericRouteBuilder(super.options);

  @override
  String get builderName => 'Generic Builder';

  @override
  Stream<Spec> generateLibrary(BuildStep buildStep) => const Stream.empty();
}

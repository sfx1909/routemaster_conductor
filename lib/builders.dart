import 'package:build/build.dart';
import 'package:recase/recase.dart';
import 'package:routemaster_conductor/src/frameworks/generic.dart';
import 'package:routemaster_conductor/src/frameworks/routemaster.dart';

///Default builder
///Will check for framework config value
Builder pageRoutes(BuilderOptions options) {
  final framework = options.config['framework'] is String
      ? options.config['framework'].toString().camelCase
      : null;
  return switch (framework) {
    'routemaster' => RoutemasterRouteBuilder(options),
    _ => GenericRouteBuilder(options)
  };
}

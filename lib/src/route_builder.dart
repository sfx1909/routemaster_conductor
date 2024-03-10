import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class RouteBuilder extends Builder {
  final BuilderOptions options;

  RouteBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['src/routes.g.dart']
    };
  }

  static AssetId _outputFile(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'src', 'routes.g.dart'),
    );
  }

  List<String> getSegments(List<String> pathSegments) {
    return pathSegments
      ..removeRange(
        0,
        pathSegments.indexWhere((element) =>
                element.toLowerCase() == 'page' ||
                element.toLowerCase() == 'pages') +
            1,
      );
  }

  List<String> getGroups(List<String> segments) => segments
      .where((element) => element.startsWith('(') && element.endsWith(')'))
      .map((e) => e.replaceFirst('(', '').replaceFirst(')', ''))
      .toList();

  List<String> getRouteSegments(List<String> segments) => segments
      .where((element) => !(element.startsWith('(') && element.endsWith(')')))
      .map((e) => e.replaceFirst('[', ':').replaceFirst(']', ''))
      .toList()
    ..removeLast();

  String getRouteName(String name, [List<String> groups = const []]) => [
        ...groups,
        name.snakeCase.replaceFirst('_page', ''),
        'route'
      ].join('_').camelCase;

  String getLayoutName(String name, [List<String> groups = const []]) => [
        ...groups,
        name.snakeCase.replaceFirst('_layout', ''),
        'layout'
      ].join('_').camelCase;

  List<String> getDynamicSlugs(List<String> segments) => segments
      .where((element) => element.startsWith(':'))
      .map((e) => e.camelCase)
      .toList();

  Stream<Spec> _generatePageRoutes(BuildStep buildStep) async* {
    final routeMetaComment =
        (options.config['routeMetaComment'] as bool?) ?? true;
    await for (final input
        in buildStep.findAssets(Glob('**/{page,pages}/**page.dart'))) {
      final library = await buildStep.resolver.libraryFor(input);
      final classes = LibraryReader(library)
          .classes
          .where((c) => c.isPublic)
          .where((c) => c.allSupertypes.any((t) => t.element.name == 'Widget'));

      final page = classes.length <= 1
          ? classes.firstOrNull
          : classes
              .where((element) =>
                  element.name.snakeCase.toLowerCase().endsWith('_page'))
              .firstOrNull;

      if (page == null) {
        throw ArgumentError(
            '"${input.uri}" does not contain any valid page classes');
      }

      final segments = getSegments(input.pathSegments);
      final groups = getGroups(segments);
      final routeSegments = getRouteSegments(segments);
      final route = '/${routeSegments.join('/')}';
      final dynamicKeys = getDynamicSlugs(routeSegments);
      final slugs = dynamicKeys.map((e) => e.replaceFirst(':', ''));
      final name = getRouteName(page.displayName, groups);

      yield Field(
        (f) {
          f
            ..name = name
            ..docs = routeMetaComment
                ? ListBuilder<String>([
                    '///File: ${input.uri}',
                    '///',
                    '///Class: ${page.displayName}',
                    '///',
                    '///Route: $route',
                    if (dynamicKeys.isNotEmpty) '///',
                    if (dynamicKeys.isNotEmpty)
                      '///Dynamic slug${slugs.length == 1 ? '' : 's'}: ${slugs.join(', ')}',
                    if (groups.isNotEmpty) '///',
                    if (groups.isNotEmpty)
                      '///Group${groups.length == 1 ? '' : 's'}: ${groups.join(', ')}'
                  ])
                : ListBuilder<String>()
            ..modifier = FieldModifier.constant;

          if (dynamicKeys.isNotEmpty) {
            f.assignment = Code(
                "NamedDynamicRoute('$route', [${slugs.map((e) => "'$e'").join(',')}])");
          } else {
            f.assignment = Code("NamedRoute('$route')");
          }
        },
      );
    }
  }

  Future<Iterable<Spec>> _generateRouteMaps(BuildStep buildStep) async {
    final groupFields =
        <String, List<String Function(String Function(Reference))>>{};

    final allTemplates = await buildStep
        .findAssets(Glob('**/{page,pages}/**template.dart'))
        .toList()
        .then(
          (value) => Map.fromEntries(
            value.map(
              (e) {
                return MapEntry(
                  '/${getRouteSegments(getSegments(e.pathSegments)).join('/')}',
                  e,
                );
              },
            ),
          ),
        );

    final unknownRoutes = await buildStep
        .findAssets(Glob('**/{page,pages}/**404.dart'))
        .toList()
        .then(
          (value) => Map.fromEntries(
            value.reversed.map(
              (e) {
                final groupName = [
                  getGroups(getSegments(e.pathSegments)).join('_'),
                  'route_map'
                ].join('_').camelCase;
                return MapEntry(
                  (
                    groupName,
                    '/${getRouteSegments(getSegments(e.pathSegments)).join('/')}'
                  ),
                  e,
                );
              },
            ).map(
              (e) => MapEntry(
                e.key.$1,
                e.value,
              ),
            ),
          ),
        );

    final mappedUnknownRoute = <String, (AssetId, FunctionElement?)?>{};

    await for (final input
        in buildStep.findAssets(Glob('**/{page,pages}/**page.dart'))) {
      final library = await buildStep.resolver.libraryFor(input);
      final classes = LibraryReader(library)
          .classes
          .where((c) => c.isPublic)
          .where((c) => c.allSupertypes.any((t) => t.element.name == 'Widget'));

      final page = classes.length <= 1
          ? classes.firstOrNull
          : classes
              .where((element) =>
                  element.name.snakeCase.toLowerCase().endsWith('_page'))
              .firstOrNull;

      if (page == null) {
        throw ArgumentError(
            '"${input.uri}" does not contain any valid page classes');
      }

      final segments = getSegments(input.pathSegments);
      final groups = getGroups(segments);
      final routeSegments = getRouteSegments(segments);
      final dynamicKeys = getDynamicSlugs(routeSegments);
      final name = getRouteName(page.displayName, groups);

      final groupName = [groups.join('_'), 'route_map'].join('_').camelCase;

      mappedUnknownRoute[groupName] = unknownRoutes.containsKey(groupName)
          ? (
              unknownRoutes[groupName]!,
              (await buildStep.resolver.libraryFor(unknownRoutes[groupName]!))
                  .topLevelElements
                  .whereType<FunctionElement>()
                  .where((element) {
                final returnType = element.returnType.element;
                final parameters = element.parameters
                    .map((e) => e.type.element?.name)
                    .whereNotNull();
                return returnType is ClassElement &&
                    !element.isPrivate &&
                    returnType.name == 'RouteSettings' &&
                    parameters.length == 1 &&
                    parameters.every((element) => element == 'String');
              }).firstOrNull
            )
          : null;

      final code = groupFields[groupName] ?? (List.empty(growable: true));

      final route = '/${routeSegments.join('/')}';
      final templateAssetId = allTemplates.entries
          .where((element) =>
              element.key == route || p.posix.isWithin(element.key, route))
          .map((e) => e.value)
          .firstOrNull;

      final templateFunction = templateAssetId == null
          ? null
          : (await buildStep.resolver.libraryFor(templateAssetId))
              .topLevelElements
              .whereType<FunctionElement>()
              .where((element) {
              final returnType = element.returnType.element;
              final parameters = element.parameters
                  .map((e) => e.type.element?.name)
                  .whereNotNull();
              return returnType is ClassElement &&
                  !element.isPrivate &&
                  returnType.name == 'RouteSettings' &&
                  parameters.length == 2 &&
                  parameters.every((element) =>
                      element == 'RouteData' || element == 'Widget');
            }).firstOrNull;

      String templatePage(String Function(Reference) ref, String page) {
        return "${ref.call(
          refer(
            templateFunction!.name,
            Uri.parse(
                    'package:${templateAssetId!.package}/${templateAssetId.path.replaceFirst(
              'lib/',
              '',
            )}')
                .toString(),
          ),
        )}(routeData,$page)";
      }

      String materialPage(String Function(Reference) ref, String page) {
        return "${ref.call(
          refer(
            'MaterialPage',
            'package:flutter/material.dart',
          ),
        )}("
            "child: $page,"
            " name: '${name.replaceFirst('Route', 'Page').snakeCase}')";
      }

      final pageTemplate =
          (templateFunction != null ? templatePage : materialPage);

      if (dynamicKeys.isNotEmpty) {
        const getParam = 'routeData.pathParameters';

        final mapped = page.constructors.first.parameters
            .where((element) => element.name != 'key')
            .map((e) {
          return switch (e) {
            ParameterElement(name: final name, isOptionalPositional: true) =>
              "$getParam['$name']",
            ParameterElement(name: final name, isPositional: true) =>
              "$getParam['$name']!",
            ParameterElement(name: final name, isOptionalNamed: true) =>
              "$name: $getParam['$name']",
            ParameterElement(name: final name, isNamed: true) =>
              "$name: $getParam['$name']!",
            _ => e.toString(),
          };
        }).join(',');

        code.add(
          (ref) => '$name.path:(routeData) => ${pageTemplate(ref, '${ref.call(
                refer(
                  page.name,
                  Uri.parse('package:${input.package}/${input.path.replaceFirst(
                    'lib/',
                    '',
                  )}')
                      .toString(),
                ),
              )}($mapped)')}',
        );
      } else {
        code.add(
          (ref) => '$name.path:(routeData) => ${pageTemplate(ref, '${ref.call(
                refer(
                  page.name,
                  Uri.parse('package:${input.package}/${input.path.replaceFirst(
                    'lib/',
                    '',
                  )}')
                      .toString(),
                ),
              )}()')}',
        );
      }

      groupFields[groupName] = code;
    }

    return groupFields.entries.map((e) => Field((m) {
          final groupName = e.key.replaceFirst('RouteMap', '');
          final (unknownRouteId, unknownRoute) =
              mappedUnknownRoute[e.key] ?? (null, null);
          m
            ..name = e.key
            ..docs = ListBuilder<String>(['/// Group: $groupName'])
            ..type = refer('RouteMap', 'package:routemaster/routemaster.dart')
            ..assignment = Code.scope((ref) => '''
            ${ref.call(refer('RouteMap', 'package:routemaster/routemaster.dart'))}(routes: {
              ${e.value.map((e) => e(ref)).join(',')}
            },
            ${unknownRoute == null ? '' : 'onUnknownRoute: ${ref.call(refer(unknownRoute.name, Uri.parse('package:${unknownRouteId!.package}/${unknownRouteId.path.replaceFirst(
                      'lib/',
                      '',
                    )}').toString()))}'}
            )
            ''');
        }));
  }

  List<Spec> _generateHelpers(BuildStep buildStep) {
    const routeSuperClass = 'INamedRoute';

    return [
      Class(
        (c) => c
          ..name = routeSuperClass
          ..sealed = true
          ..docs = ListBuilder<String>([
            '/// A representation of a named route.',
            '///',
            '/// Allows for creating extensions on paths.',
          ])
          ..fields = ListBuilder<Field>(
            [
              Field(
                (f) => f
                  ..name = 'path'
                  ..modifier = FieldModifier.final$
                  ..type = const Reference('String'),
              ),
            ],
          )
          ..constructors = ListBuilder<Constructor>([
            Constructor(
              (c) => c
                ..constant = true
                ..requiredParameters = ListBuilder<Parameter>(
                  [
                    Parameter(
                      (p) => p
                        ..name = 'path'
                        ..toThis = true,
                    ),
                  ],
                ),
            )
          ]),
      ),
      Class(
        (c) => c
          ..name = 'NamedRoute'
          ..extend = const Reference(routeSuperClass)
          ..docs = ListBuilder<String>([
            '/// A representation of a named route.',
            '///',
            '/// Allows for creating extensions on paths.',
          ])
          ..modifier = ClassModifier.final$
          ..constructors = ListBuilder<Constructor>([
            Constructor(
              (c) => c
                ..constant = true
                ..requiredParameters = ListBuilder<Parameter>(
                  [
                    Parameter(
                      (p) => p
                        ..name = 'path'
                        ..toSuper = true,
                    ),
                  ],
                ),
            )
          ]),
      ),
      Class(
        (c) => c
          ..name = 'NamedDynamicRoute'
          ..extend = const Reference(routeSuperClass)
          ..modifier = ClassModifier.final$
          ..docs = ListBuilder<String>([
            '/// A representation of a dynamic named route.',
            '///',
            '/// Allows for creating extensions on paths.',
          ])
          ..constructors = ListBuilder<Constructor>([
            Constructor(
              (c) => c
                ..constant = true
                ..requiredParameters = ListBuilder<Parameter>(
                  [
                    Parameter(
                      (p) => p
                        ..name = 'path'
                        ..toSuper = true,
                    ),
                    Parameter(
                      (p) => p
                        ..name = 'slugs'
                        ..toThis = true,
                    ),
                  ],
                ),
            )
          ])
          ..fields = ListBuilder<Field>(
            [
              Field(
                (f) => f
                  ..name = 'slugs'
                  ..modifier = FieldModifier.final$
                  ..type = const Reference('List<String>'),
              ),
            ],
          )
          ..methods = ListBuilder<Method>([
            Method(
              (m) => m
                ..docs = ListBuilder<String>([
                  '/// Applies path params to the path where keys match.',
                  '///',
                  '/// Unmatched path keys will cause this method to return a `NamedDynamicRoute` where normally a `NamedRoute` will be returned.'
                ])
                ..name = 'applyPathParams'
                ..returns = const Reference(routeSuperClass)
                ..requiredParameters = ListBuilder<Parameter>(
                  [
                    Parameter(
                      (p) => p
                        ..name = 'params'
                        ..type = const Reference('Map<String,dynamic>'),
                    ),
                  ],
                )
                ..body = const Code('''
                  final segments = path.split('/').map((part) {
                    final key = part.replaceFirst(':','');
                    
                    if (!params.containsKey(key)) {
                      return part;
                    }
                    
                    return params[key].toString();
                  });
                  final route = segments.join('/');
                  
                  if (segments.any((part) => part.startsWith(':'))) {
                    return NamedDynamicRoute(route, slugs);
                  }            
                  
                  return NamedRoute(route);                  
                  '''),
            )
          ]),
      )
    ];
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final outputFile = _outputFile(buildStep);

    final emitter = DartEmitter.scoped();
    final formatter = DartFormatter(fixes: [
      StyleFix.docComments,
      StyleFix.namedDefaultSeparator,
      StyleFix.singleCascadeStatements,
    ], pageWidth: 80);

    final spec = List.empty(growable: true);

    spec.addAll(_generateHelpers(buildStep));

    spec.addAll(await _generatePageRoutes(buildStep).toList());

    final buildRouteMap = (options.config['buildRouteMap'] as bool?) ?? true;
    if (buildRouteMap) {
      spec.addAll(await _generateRouteMaps(buildStep));
    }

    final library = Library(
      (l) => l
        ..comments = ListBuilder([
          ''.padRight(24, '='),
          '${'='.padRight(5, ' ')}GENERATED FILE${'='.padLeft(5, ' ')}',
          ''.padRight(24, '='),
          '',
          'Do not modify by hand'
        ])
        ..generatedByComment = 'Generated by routemaster_conductor'
        ..ignoreForFile = ListBuilder<String>([
          'prefer_relative_imports',
          'prefer_const_constructors',
        ])
        ..name = 'routes'
        ..body = ListBuilder(spec),
    );

    await buildStep.writeAsString(
      outputFile,
      formatter.format(
        '${library.accept(emitter)}',
      ),
    );
  }
}

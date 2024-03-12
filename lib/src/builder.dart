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

abstract class RouteBuilder extends Builder {
  final BuilderOptions options;

  RouteBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    var output = options.config['outputDir'];
    if (output is String) {
      final split = p.split(output);
      if (split.first == 'lib') {
        split.removeAt(0);
      }
      output = p.joinAll(split);
    }

    return {
      r'$lib$': [
        p.joinAll([output ?? 'src', 'routes.g.dart'])
      ]
    };
  }

  String get builderName;

  /// Generates the actual library code if available.
  Stream<Spec> generateLibrary(BuildStep buildStep);

  AssetId _outputFile(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.joinAll([options.config['outputDir'] ?? 'lib/src', 'routes.g.dart']),
    );
  }

  Stream<RouteAsset<ClassElement>> getPages(BuildStep buildStep) =>
      getAssets<ClassElement>(
        buildStep: buildStep,
        glob: Glob('**/{page,pages}/**page.dart'),
        test: (element) =>
            element.isPublic &&
            element.allSupertypes.any(
              (t) =>
                  t.element.name == 'Widget' &&
                  element.name.snakeCase.toLowerCase().endsWith('_page'),
            ),
      );

  Stream<RouteAsset<FunctionElement>> getUnknowns(BuildStep buildStep) =>
      getAssets<FunctionElement>(
        buildStep: buildStep,
        glob: Glob('**/{page,pages}/**{404,unknown}.dart'),
        test: (element) {
          final returnType = element.returnType.element;
          return returnType is ClassElement &&
              element.isPublic &&
              returnType.name == 'RouteSettings';
        },
      );

  Stream<RouteAsset<FunctionElement>> getTemplates(BuildStep buildStep) =>
      getAssets<FunctionElement>(
        buildStep: buildStep,
        glob: Glob('**/{page,pages}/**template.dart'),
        test: (element) {
          final returnType = element.returnType.element;
          return returnType is ClassElement &&
              element.isPublic &&
              returnType.name == 'RouteSettings';
        },
      );

  Stream<RouteAsset<FunctionElement>> getNested(BuildStep buildStep) =>
      getAssets<FunctionElement>(
        buildStep: buildStep,
        glob: Glob('**/{page,pages}/**{nested,tabs}.dart'),
        test: (element) {
          final returnType = element.returnType.element;
          return returnType is ClassElement &&
              element.isPublic &&
              returnType.name == 'RouteSettings';
        },
      );

  Stream<Spec> generatePageRoutesFields(BuildStep buildStep) async* {
    final routeMetaComment =
        (options.config['routeMetaComment'] as bool?) ?? true;
    await for (final asset in getPages(buildStep)) {
      yield Field(
        (f) {
          f
            ..name = asset.routeName
            ..docs = routeMetaComment
                ? ListBuilder<String>([
                    '///File: ${asset.id.uri}',
                    '///',
                    '///Class: ${asset.element.displayName}',
                    '///',
                    '///Route: ${asset.route}',
                    if (asset.slugs.isNotEmpty) '///',
                    if (asset.slugs.isNotEmpty)
                      '///Dynamic slug${asset.slugs.length == 1 ? '' : 's'}: ${asset.slugs.join(', ')}',
                    if (asset.groups.isNotEmpty) '///',
                    if (asset.groups.isNotEmpty)
                      '///Group${asset.groups.length == 1 ? '' : 's'}: ${asset.groups.join(', ')}'
                  ])
                : ListBuilder<String>()
            ..modifier = FieldModifier.constant;

          if (asset.slugs.isNotEmpty) {
            f.assignment = Code(
              "NamedDynamicRoute('${asset.route}', [${asset.slugs.map((e) => "'$e'").join(',')}])",
            );
          } else {
            f.assignment = Code("NamedRoute('${asset.route}')");
          }
        },
      );
    }
  }

  List<Spec> generateHelpers(BuildStep buildStep) {
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

    List<Spec> spec = List.empty(growable: true)
      ..addAll(
        buildStep.trackStage(
          'generateHelpers',
          () => generateHelpers(
            buildStep,
          ),
        ),
      )
      ..addAll(
        await buildStep.trackStage(
          'generatePageRoutes',
          () => generatePageRoutesFields(buildStep).toList(),
        ),
      )
      ..addAll(
        await buildStep.trackStage(
          'generateLibrary',
          () => generateLibrary(buildStep).toList(),
        ),
      );

    final library = Library(
      (l) => l
        ..comments = ListBuilder([
          ''.padRight(24, '='),
          '${'='.padRight(5, ' ')}GENERATED FILE${'='.padLeft(5, ' ')}',
          ''.padRight(24, '='),
          '',
          'Do not modify by hand'
        ])
        ..generatedByComment =
            'Generated by routemaster_conductor using $builderName'
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

  Stream<RouteAsset<E>> getAssets<E extends Element>({
    required BuildStep buildStep,
    required Glob glob,
    required bool Function(E element) test,
  }) async* {
    await for (final assetId in buildStep.findAssets(glob)) {
      final library = await buildStep.resolver.libraryFor(assetId);

      for (final element in library.topLevelElements.whereType<E>()) {
        if (test(element)) {
          yield (switch (element) {
            ClassElement() =>
              RouteAsset<ClassElement>(id: assetId, element: element),
            FunctionElement() =>
              RouteAsset<FunctionElement>(id: assetId, element: element),
            _ => throw UnimplementedError(E.runtimeType.toString()),
          }) as RouteAsset<E>;
        }
      }
    }
  }
}

final class RouteAsset<E extends Element> {
  final AssetId id;
  final E element;

  RouteAsset({required this.id, required this.element});

  List<String> get segments {
    return List<String>.from(id.pathSegments)
      ..removeRange(
        0,
        id.pathSegments.indexWhere((element) =>
                element.toLowerCase() == 'page' ||
                element.toLowerCase() == 'pages') +
            1,
      );
  }

  List<String> get routeSegments {
    return List<String>.from(segments)
        .where((element) => !(element.startsWith('(') && element.endsWith(')')))
        .map((e) => e.replaceFirst('[', ':').replaceFirst(']', ''))
        .toList()
      ..removeLast();
  }

  String get route => '/${routeSegments.join('/')}';

  List<String> get groups => segments
      .where((element) => element.startsWith('(') && element.endsWith(')'))
      .map((e) => e.replaceFirst('(', '').replaceFirst(')', ''))
      .toList();

  String _getName({required String? suffix, String replace = ''}) {
    return [
      ...groups,
      element.displayName.snakeCase.replaceFirst(replace, ''),
      suffix
    ].whereNotNull().join('_').camelCase;
  }

  String get routeName => _getName(suffix: 'route', replace: '_page');

  List<String> get slugs => routeSegments
      .where((element) => element.startsWith(':'))
      .map((e) => e.replaceFirst(':', '').camelCase)
      .toList();
}

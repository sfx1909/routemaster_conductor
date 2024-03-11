import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';
import 'package:routemaster_conductor/src/builder.dart';

class RoutemasterRouteBuilder extends RouteBuilder {
  RoutemasterRouteBuilder(super.options);

  @override
  String get builderName => 'Routemaster Builder';

  @override
  Stream<Spec> generateLibrary(BuildStep buildStep) async* {
    final pages = await getPages(buildStep).toList();
    final allTemplates = await getTemplates(buildStep).toList();
    final allUnknowns = await getUnknowns(buildStep).toList();

    final SplayTreeMap<String,
            List<String Function(String Function(Reference))>> groups =
        SplayTreeMap();
    final SplayTreeMap<String, RouteAsset<FunctionElement>?> groupUnknowns =
        SplayTreeMap();

    String getGroupName(List<String> groups) =>
        [groups.join('_'), 'route_map'].join('_').camelCase;

    for (final page in pages) {
      final groupName = getGroupName(page.groups);

      final pageDir = page.route;
      final pageGroupPath = joinAll(['/', ...page.groups]);
      final templateAsset = allTemplates.where((templ) {
        final tempDir = templ.route;
        final tempGroupPath = joinAll(['/', ...templ.groups]);

        return (pageDir == tempDir || isWithin(tempDir, pageDir)) &&
            (pageGroupPath == tempGroupPath ||
                isWithin(tempGroupPath, pageGroupPath));
      }).firstOrNull;

      final unknownAsset = allUnknowns.where((unknown) {
        final unknownDir = unknown.route;
        final unknownGroupPath = joinAll(['/', ...unknown.groups]);

        return (pageDir == unknownDir || isWithin(unknownDir, pageDir)) &&
            (pageGroupPath == unknownGroupPath ||
                isWithin(unknownGroupPath, pageGroupPath));
      }).lastOrNull;

      groupUnknowns.putIfAbsent(groupName, () => unknownAsset);

      final templateFunction = templateAsset?.element;

      String templatePage(String Function(Reference) ref, String pageString) {
        return "${ref.call(
          refer(
            templateFunction!.name,
            Uri.parse('package:${templateAsset!.id.package}'
                    '/${templateAsset.id.path.replaceFirst(
              'lib/',
              '',
            )}')
                .toString(),
          ),
        )}(routeData,$pageString)";
      }

      String materialPage(String Function(Reference) ref, String pageString) {
        return "${ref.call(
          refer(
            'MaterialPage',
            'package:flutter/material.dart',
          ),
        )}("
            "child: $pageString,"
            " name: '${page.routeName.replaceFirst(
                  'Route',
                  'Page',
                ).snakeCase}')";
      }

      final pageTemplate =
          (templateFunction != null ? templatePage : materialPage);

      final code = groups[groupName] ?? (List.empty(growable: true));

      const getParam = 'routeData.pathParameters';

      final mapped = page.element.constructors.first.parameters
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
        (ref) => '${page.routeName}.path:(routeData) => ${pageTemplate(
          ref,
          '${ref.call(
            refer(
              page.element.name,
              Uri.parse('package:${page.id.package}'
                      '/${page.id.path.replaceFirst(
                'lib/',
                '',
              )}')
                  .toString(),
            ),
          )}($mapped)',
        )}',
      );

      groups[groupName] = code;
    }

    for (final entry in groups.entries) {
      yield Field((m) {
        final groupName = entry.key.replaceFirst('RouteMap', '');
        final unknown = groupUnknowns[entry.key];
        m
          ..name = entry.key
          ..docs = ListBuilder<String>(['/// Group: $groupName'])
          ..type = refer('RouteMap', 'package:routemaster/routemaster.dart')
          ..assignment = Code.scope((ref) => '''
              ${ref.call(
                refer(
                  'RouteMap',
                  'package:routemaster/routemaster.dart',
                ),
              )}(routes: {
                ${entry.value.map((e) => e(ref)).join(',')}
              },
              ${unknown == null ? '' : 'onUnknownRoute: ${ref.call(
                  refer(
                    unknown.element.name,
                    Uri.parse(
                      'package:${unknown.id.package}'
                      '/${unknown.id.path.replaceFirst(
                        'lib/',
                        '',
                      )}',
                    ).toString(),
                  ),
                )}'}
              )
              ''');
      });
    }
  }

  @override
  Stream<RouteAsset<FunctionElement>> getUnknowns(BuildStep buildStep) {
    return super.getUnknowns(buildStep).takeWhile((element) {
      final parameters = element.element.parameters
          .map((e) => e.type.element?.name)
          .whereNotNull();
      return parameters.length == 1 &&
          parameters.every((param) => param == 'String');
    });
  }

  @override
  Stream<RouteAsset<FunctionElement>> getTemplates(BuildStep buildStep) {
    return super.getTemplates(buildStep).takeWhile((element) {
      final parameters = element.element.parameters
          .map((e) => e.type.element?.name)
          .whereNotNull();
      return parameters.length == 2 &&
          parameters
              .every((param) => param == 'RouteData' || param == 'Widget');
    });
  }
}

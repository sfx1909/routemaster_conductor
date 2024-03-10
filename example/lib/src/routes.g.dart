// ========================
// =    GENERATED FILE    =
// ========================
//
// Do not modify by hand

// Generated by routemaster_conductor

// ignore_for_file: prefer_const_constructors, prefer_relative_imports

library routes; // ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:routemaster/routemaster.dart' as _i1;
import 'package:example/src/page/(dynamic)/user/%5Bid%5D/blog/%5Bblog_id%5D/page.dart'
    as _i2;
import 'package:example/src/page/(tabs)/template.dart' as _i3;
import 'package:example/src/page/(dynamic)/user/%5Bid%5D/page.dart' as _i4;
import 'package:example/src/page/(dynamic)/user/%5Bid%5D/settings/page.dart'
    as _i5;
import 'package:example/src/page/(dynamic)/user/%5Bid%5D/settings/%5Bsetting%5D/page.dart'
    as _i6;
import 'package:example/src/page/(guarded)/page.dart' as _i7;
import 'package:example/src/page/(guarded)/some/page.dart' as _i8;
import 'package:example/src/page/(redirect)/page.dart' as _i9;
import 'package:example/src/page/(redirect)/some/page.dart' as _i10;
import 'package:example/src/page/(tabs)/one/page.dart' as _i11;
import 'package:example/src/page/(tabs)/page.dart' as _i12;
import 'package:example/src/page/(tabs)/two/page.dart' as _i13;
import 'package:example/src/page/(tabs)/404.dart' as _i14;
import 'package:example/src/page/page.dart' as _i15;
import 'package:example/src/page/404.dart' as _i16;

/// A representation of a named route.
///
/// Allows for creating extensions on paths.
sealed class INamedRoute {
  const INamedRoute(this.path);

  final String path;
}

/// A representation of a named route.
///
/// Allows for creating extensions on paths.
final class NamedRoute extends INamedRoute {
  const NamedRoute(super.path);
}

/// A representation of a dynamic named route.
///
/// Allows for creating extensions on paths.
final class NamedDynamicRoute extends INamedRoute {
  const NamedDynamicRoute(
    super.path,
    this.slugs,
  );

  final List<String> slugs;

  /// Applies path params to the path where keys match.
  ///
  /// Unmatched path keys will cause this method to return a `NamedDynamicRoute` where normally a `NamedRoute` will be returned.
  INamedRoute applyPathParams(Map<String, dynamic> params) {
    final segments = path.split('/').map((part) {
      final key = part.replaceFirst(':', '');

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
  }
}

///File: package:example/src/page/(dynamic)/user/%5Bid%5D/blog/%5Bblog_id%5D/page.dart
///
///Class: BlogPostPage
///
///Route: /user/:id/blog/:blog_id
///
///Dynamic slugs: id, blogId
///
///Group: dynamic
const dynamicBlogPostRoute =
    NamedDynamicRoute('/user/:id/blog/:blog_id', ['id', 'blogId']);

///File: package:example/src/page/(dynamic)/user/%5Bid%5D/page.dart
///
///Class: UserPage
///
///Route: /user/:id
///
///Dynamic slug: id
///
///Group: dynamic
const dynamicUserRoute = NamedDynamicRoute('/user/:id', ['id']);

///File: package:example/src/page/(dynamic)/user/%5Bid%5D/settings/page.dart
///
///Class: SettingsPage
///
///Route: /user/:id/settings
///
///Dynamic slug: id
///
///Group: dynamic
const dynamicSettingsRoute = NamedDynamicRoute('/user/:id/settings', ['id']);

///File: package:example/src/page/(dynamic)/user/%5Bid%5D/settings/%5Bsetting%5D/page.dart
///
///Class: SettingPage
///
///Route: /user/:id/settings/:setting
///
///Dynamic slugs: id, setting
///
///Group: dynamic
const dynamicSettingRoute =
    NamedDynamicRoute('/user/:id/settings/:setting', ['id', 'setting']);

///File: package:example/src/page/(guarded)/page.dart
///
///Class: UnguardedPage
///
///Route: /
///
///Group: guarded
const guardedUnguardedRoute = NamedRoute('/');

///File: package:example/src/page/(guarded)/some/page.dart
///
///Class: GuardedPage
///
///Route: /some
///
///Group: guarded
const guardedGuardedRoute = NamedRoute('/some');

///File: package:example/src/page/(redirect)/page.dart
///
///Class: RedirectPage
///
///Route: /
///
///Group: redirect
const redirectRedirectRoute = NamedRoute('/');

///File: package:example/src/page/(redirect)/some/page.dart
///
///Class: RedirectedPage
///
///Route: /some
///
///Group: redirect
const redirectRedirectedRoute = NamedRoute('/some');

///File: package:example/src/page/(tabs)/one/page.dart
///
///Class: OnePage
///
///Route: /one
///
///Group: tabs
const tabsOneRoute = NamedRoute('/one');

///File: package:example/src/page/(tabs)/page.dart
///
///Class: TabsPage
///
///Route: /
///
///Group: tabs
const tabsTabsRoute = NamedRoute('/');

///File: package:example/src/page/(tabs)/two/page.dart
///
///Class: TwoPage
///
///Route: /two
///
///Group: tabs
const tabsTwoRoute = NamedRoute('/two');

///File: package:example/src/page/page.dart
///
///Class: AppPage
///
///Route: /
const appRoute = NamedRoute('/');

/// Group: dynamic
_i1.RouteMap dynamicRouteMap = _i1.RouteMap(
  routes: {
    dynamicBlogPostRoute.path: (routeData) => _i3.tabTemplate(
        routeData,
        _i2.BlogPostPage(
            blogId: routeData.pathParameters['blogId']!,
            id: routeData.pathParameters['id']!)),
    dynamicUserRoute.path: (routeData) => _i3.tabTemplate(
        routeData, _i4.UserPage(id: routeData.pathParameters['id']!)),
    dynamicSettingsRoute.path: (routeData) => _i3.tabTemplate(
        routeData, _i5.SettingsPage(id: routeData.pathParameters['id']!)),
    dynamicSettingRoute.path: (routeData) =>
        _i3.tabTemplate(routeData, _i6.SettingPage())
  },
);

/// Group: guarded
_i1.RouteMap guardedRouteMap = _i1.RouteMap(
  routes: {
    guardedUnguardedRoute.path: (routeData) =>
        _i3.tabTemplate(routeData, _i7.UnguardedPage()),
    guardedGuardedRoute.path: (routeData) =>
        _i3.tabTemplate(routeData, _i8.GuardedPage())
  },
);

/// Group: redirect
_i1.RouteMap redirectRouteMap = _i1.RouteMap(
  routes: {
    redirectRedirectRoute.path: (routeData) =>
        _i3.tabTemplate(routeData, _i9.RedirectPage()),
    redirectRedirectedRoute.path: (routeData) =>
        _i3.tabTemplate(routeData, _i10.RedirectedPage())
  },
);

/// Group: tabs
_i1.RouteMap tabsRouteMap = _i1.RouteMap(routes: {
  tabsOneRoute.path: (routeData) => _i3.tabTemplate(routeData, _i11.OnePage()),
  tabsTabsRoute.path: (routeData) =>
      _i3.tabTemplate(routeData, _i12.TabsPage()),
  tabsTwoRoute.path: (routeData) => _i3.tabTemplate(routeData, _i13.TwoPage())
}, onUnknownRoute: _i14.unknownRoute);

/// Group: routeMap
_i1.RouteMap routeMap = _i1.RouteMap(routes: {
  appRoute.path: (routeData) => _i3.tabTemplate(routeData, _i15.AppPage())
}, onUnknownRoute: _i16.unknownRoute);
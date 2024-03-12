# Routemaster Conductor

[![pub](https://img.shields.io/pub/v/routemaster_conductor.svg)](https://pub.dev/packages/routemaster_conductor)

Routemaster Conductor was built to mimic how [Next.js](https://nextjs.org/docs/app/building-your-application/routing)
does its routing, with routemaster's path param, nested routes and
route map switching. The main goal is to maintain the interface that Routemaster provides and help with generating the
boilerplate.

__We don't depend on routemaster we just provide first party support__, the filesystem paths are generated and assigned
to helper classes we also generate that provide a named route functionality.

## Table of Contents

<!-- TOC -->
* [Routemaster Conductor](#routemaster-conductor)
  * [Table of Contents](#table-of-contents)
  * [Motivation](#motivation)
  * [Getting started](#getting-started)
    * [Install](#install)
    * [Project structure](#project-structure)
      * [Folders](#folders)
      * [Files](#files)
      * [Example](#example)
  * [Configuration](#configuration)
  * [Features](#features)
    * [Partial support](#partial-support)
  * [Dynamic routes](#dynamic-routes)
  * [404/Unknown routes](#404unknown-routes)
  * [Templates](#templates)
    * [Routemaster](#routemaster)
      * [template.dart](#templatedart)
      * [404.dart](#404dart)
      * [nested.dart](#nesteddart)
<!-- TOC -->

## Motivation

Thought it was an interesting concept and my paths are generally the same as the folder structure; and there are enough
navigation frameworks already.

## Getting started

### Install

```shell
flutter pub add dev:build_runner dev:routemaster_conductor
```

If you want routemaster

```shell
flutter pub add dev:build_runner dev:routemaster_conductor routemaster
```

### Project structure

We check for pages in `.../pages/...` and `.../page/...`, we don't really care where you put them in your project. The
routes will get placed in `lib/src/routes.g.dart` though. (_See configuration for override option_)

#### Folders

| Folder        | Type    | Example                           | Route      |
|---------------|---------|-----------------------------------|------------|
| pages/\<dir>/ | Segment | pages/home/page.dart              | /home      |
| pages/[key]/  | Slug    | pages/user/[id]/page.dart         | /user/:id  |
| pages/(name)/ | Group   | pages/(admin)/dashboard/page.dart | /dashboard |

#### Files

| File                  | Type     | Description                                                                                      |
|-----------------------|----------|--------------------------------------------------------------------------------------------------|
| page.dart             | Page     | Used to define a page for a give route                                                           |
| template.dart         | Template | Used to override the default RouteSettings factory that routemaster uses                         |
| 404.dart,unknown.dart | Unknown  | Used to define a 404 page for the current route map. Its recommended to place one in each group. |
| tabs.dart,nested.dart | Nested   | Used to define a nested route, or tabbed route.                                                  |

* __Note:__ Templates will cascade down the file tree until another template is found.

#### Example

You can check the `example/` folder for usage there is an example of each supported feature

## Configuration

```yaml 
# build.yaml
targets:
  $default:
    builders:
      routemaster_conductor:
        options:
          routeMetaComment: true
          framework: routemaster
```

| Option             | Description                                                                                           | Default         | Allowed values                          | Nullable |
|--------------------|-------------------------------------------------------------------------------------------------------|-----------------|-----------------------------------------|----------|
| `routeMetaComment` | Disables generating metadata comments on routes                                                       | `true`          | `true`,`false`                          | `true`   |
| `framework`        | Generates different route maps depending on the framework. `null` will generate only the named routes | `'routemaster'` | `'routemaster'`,`null`                  | `true`   |
| `outputDir`        | Overwrites the default output directory of `rouets.g.dart`                                            | `lib/src`       | Any valid path relative to project root | `true`   |

## Features

- Generate routes from file system
- Allow for dynamic routes with route slugs
- Route grouping
    - This is similar to [Next.js' grouping](https://nextjs.org/docs/app/building-your-application/routing/route-groups)
      except we generate a new route map for each group
    - This is to allow for [routemaster's route map swapping](https://pub.dev/packages/routemaster#swap-routing-map)
- 404/Unknown routes
- Nested Routes/Tabs

### Partial support

- Redirect
    - We sort of support this feature through templates
    - Might change in future

## Dynamic routes

When it comes to dynamic route slugs you can add a String params to your constructor of your page, and we will assume
the constructor param is the same as the slug id in the path, don't worry about optional, named and required params we
should handle all of them.

You don't need to use the constructor method at all you can also access it through routemaster.

## 404/Unknown routes

Each route group has its own 404-page by default the routemaster one is used. These work similar to templates.

## Templates

### Routemaster

These templates are specific to the routemaster builder

#### template.dart

```dart
RouteSettings routeTemplate(RouteData routeData, Widget child) {
  return //Your code here
}
```

#### 404.dart

```dart
RouteSettings unknownRoute(String path) {
  return //Your code here
}
```

#### nested.dart

The page in the same directory as the nested route will ignore the template, but the template will get applied to
subpages.

```dart
RouteSettings nestedRoute(RouteData routeData, Widget child) {
  return //Your code here
}
```
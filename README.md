# Routemaster Conductor

Routemaster Conductor was built to mimic how [Next.js](https://nextjs.org/docs/app/building-your-application/routing)
does its routing, with routemaster's path param, nested routes and
route map switching. The main goal is to maintain the interface that Routemaster provides and help with generating the
boilerplate.

__We don't depend on routemaster we just provide first party support__, the filesystem paths are generated and assigned
to helper classes we also generate that provide a named route functionality.

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
routes will get placed in `lib/src/routes.g.dart` though. (_Might allow configuration in later versions_)

#### Folders

| Folder        | Type    | Example                           | Route      |
|---------------|---------|-----------------------------------|------------|
| pages/\<dir>/ | Segment | pages/home/page.dart              | /home      |
| pages/[key]/  | Slug    | pages/user/[id]/page.dart         | /user/:id  |
| pages/(name)/ | Group   | pages/(admin)/dashboard/page.dart | /dashboard |

#### Files

| File          | Type     | Description                                                              |
|---------------|----------|--------------------------------------------------------------------------|
| page.dart     | Page     | Used to define a page for a give route                                   |
| template.dart | Template | Used to override the default RouteSettings factory that routemaster uses |

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
          # Removes route metadata doc comments. Default: true
          routeMetaComment: true
          # Generates routemaster route maps and import routemaster. Default: true
          # Setting to false will remove routemaster dependency
          buildRouteMap: true 
```

## Features

- Generate routes from file system
- Allow for dynamic routes with route slugs
- Route grouping
    - This is similar to [Next.js' grouping](https://nextjs.org/docs/app/building-your-application/routing/route-groups)
      except we generate a new route map for each group
    - This is to allow for [routemaster's route map swapping](https://pub.dev/packages/routemaster#swap-routing-map)
- 404/Unknown routes

### Partial support

- Nested Routes/Tabs
    - We sort of support this feature through templates
    - Might change in future
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

### template.dart

```dart
RouteSettings guardTemplate(RouteData routeData, Widget child) {
  return //Your code here
}
```

### 404.dart

```dart
RouteSettings unknownRoute(String path) {
  return //Your code here
}
```
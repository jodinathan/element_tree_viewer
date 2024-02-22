import 'dart:io';

import 'package:ackable/broadcast/websocket.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:collection/collection.dart';
import 'package:element_tree_console/src/generator/reflector.dart';

import 'package:element_tree_console/src/metadata.dart';
import 'package:element_tree_console/src/tree.dart';

Future<void> main(List<String> args) async {
  final arg = args.first;
  //final encoder = JsonEncoder.withIndent('  ');

  if (FileSystemEntity.isDirectorySync(arg)) {
    throw 'Cant use directory: $arg.';
  }

  print('start $arg');

  final tree = await parseTree(arg);
  ElementItem? currentItem;

  final server = WebSocketAckableServer('tree-viewer', port: 4040);

  await server.start();

  print('\n\nWaiting...');
  // 181

  Iterable<Map<String, dynamic>>? byLocation(int offset) {
    final element = tree.tryFindByOffset(offset);

    if (element == null) {
      print(
          'NOT FOUND! =/ $offset\n${tree.items.map((i) => '${i.node.offset}->${i.node.end}').join('\n')}');
      return null;
    }

    currentItem = element;

    final ret = tree.itemToMap(element);

    return ret;
  }

  // byLocation(180);

  // final mappable = tree.tryDigProperty(currentItem!, ['metadata']);
  // print('mappable: ${mappable!.analyzer}, \n${mappable.item}');
  // print(encoder.convert(tree.mappableToMap(mappable!)));
  // print('second-stuff');

  await server.onClient.forEach((socket) {
    socket
      ..onCommand('location', (message) {
        final offset = message.data as int;

        return byLocation(offset);
      })
      ..onCommand('sub', (message) {
        final mappable = tree.tryDigProperty(
            currentItem!, (message.data as Iterable).cast<String>())!;
        final ret = tree.mappableToMap(mappable);

        return ret;
      });
  });
}

Future<ElementTree> parseTree(String filePath) async {
  final entity = File(filePath);

  if (!entity.existsSync()) {
    throw 'File not found: $filePath';
  }

  final collection = AnalysisContextCollection(
      includedPaths: [entity.absolute.path],
      resourceProvider: PhysicalResourceProvider.INSTANCE);
  final items = <ElementItem>[];

  for (final context in collection.contexts) {
    for (final filePath in context.contextRoot.analyzedFiles()) {
      if (!filePath.endsWith('.dart')) {
        continue;
      }

      final analysisSession = context.currentSession;
      var result = await analysisSession.getResolvedUnit(filePath);

      if (result is! ResolvedUnitResult) {
        throw 'Couldnt resolve unit ($result): $filePath';
      }

      final libraryElement = result.libraryElement;
      final parsedLib = analysisSession
          .getParsedLibraryByElement(libraryElement) as ParsedLibraryResult;

      print(
          'Element and nodes: ${result.libraryElement.topLevelElements.map((el) => '${el.runtimeType} (${el.name}): [${el.children.map((e) => '-- "${e.runtimeType}": $e').join('\n')}]').join('\n')}\n\n');

      SyntacticEntity? tryGetNodeFromList(
          Element element, Iterable<SyntacticEntity> entities) {
        for (final entity in entities) {
          if ((entity is Directive && entity.element == element) ||
              (entity is Declaration && entity.declaredElement == element)) {
            return entity;
          }
        }

        for (final entity in entities) {
          if (entity is AstNode) {
            final children = <SyntacticEntity>[
              ...entity.childEntities,
              if (entity is MethodDeclaration)
                ...(entity.typeParameters?.typeParameters ?? [])
            ];
            final ret = tryGetNodeFromList(element, children);

            if (ret != null) {
              return ret;
            }
          }
        }

        return null;
      }

      SyntacticEntity? tryGetNode(Element el) {
        final ret = parsedLib.getElementDeclaration(el)?.node ??
            result.unit.declarations
                .firstWhereOrNull((node) => node.declaredElement == el);

        if (ret != null) {
          return ret;
        }

        return tryGetNodeFromList(el, result.unit.childEntities);
      }

      SyntacticEntity getNode(Element el) {
        final ret = tryGetNode(el);

        if (ret == null) {
          throw 'Couldnt find node for ${el.runtimeType}: $el';
        }

        return ret;
      }

      ReflectItem<Element> getMetadata(Element el) {
        final ret = reflectedElements.firstWhereOrNull((m) => m.checker(el));

        if (ret == null) {
          throw 'Couldnt find metadata for ${el.runtimeType}';
        }

        return ret as ReflectItem<Element>;
      }

      final libNode = tryGetNode(libraryElement.library);

      if (libNode != null) {
        items.add(ElementItem(
            analyzer: getMetadata(libraryElement),
            item: libraryElement,
            node: libNode));
      }

      void processItems(Iterable<Element> elements) {
        for (final item in elements) {
          if (item.isSynthetic) {
            continue;
          }

          items.add(ElementItem(
              analyzer: getMetadata(item), item: item, node: getNode(item)));

          processItems(item.children);
        }
      }

      processItems(result.libraryElement.topLevelElements);
    }
  }

  return ElementTree(items: items, reflectedItems: reflectedElements);
}

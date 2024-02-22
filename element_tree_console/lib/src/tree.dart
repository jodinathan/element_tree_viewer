import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:collection/collection.dart';

import 'generator/reflector.dart';

class ElementItem<T extends Object> {
  ElementItem({required this.analyzer, required this.item, required this.node});

  final ReflectItem<T> analyzer;
  final T item;
  final SyntacticEntity node;

  @override
  String toString() => '''
========
    item: ${item.runtimeType} => $item,
    node: $node,
    analyzer: $analyzer,
      props: 
      ${analyzer.properties.map((p) => '${p.name}: ${p.type}').join('\n')}
  ''';
}

enum ValueKind { constant, list, unknown, known }

typedef MappableItem = ({ReflectItem analyzer, Object item});

class ElementTree<T extends Object> {
  ElementTree({required this.items, required this.reflectedItems})
      : sortedItems = items.sortedByLocation();

  final Iterable<ElementItem<T>> items;
  final Iterable<ElementItem<T>> sortedItems;
  final Iterable<ReflectItem<T>> reflectedItems;

  ElementItem? tryFindByOffset(int offset) {
    return items.firstWhereOrNull(
        (it) => it.node.offset <= offset && it.node.end >= offset);
  }

  ElementItem findByOffset(int offset) => tryFindByOffset(offset)!;

  MappableItem? tryDigProperty(ElementItem element, Iterable<String> path) {
    var current = element.analyzer;
    Object? obj = element.item;

    for (var x = 0; x < path.length; x++) {
      final name = path.elementAt(x);
      final index = int.tryParse(name);

      if (index != null) {
        if (obj is! Iterable) {
          throw 'Obj should be iterable! ${obj?.runtimeType} given. index: $index';
        }

        obj = obj.elementAt(index);
        continue;
      }

      final prop =
          current.properties.firstWhere((element) => element.name == name);

      obj = prop.getter(obj!);

      if (obj == null || !prop.isViewable) {
        return null;
      }

      final reflect = reflectedItems.firstWhereOrNull(
          (r) => obj is Iterable ? r.type == prop.type : r.checker(obj));

      if (reflect == null) {
        print(reflectedItems
            .map((r) => 'r: ${r.type} == ${prop.type} = ${r.type == prop.type}')
            .join('\n'));
        throw 'Couldnt find reflected for ${obj.runtimeType}(${prop.type}) => $obj';
      }

      current = reflect;
    }

    return (analyzer: current, item: obj!);
  }

  String runtimeTypeName(dynamic item) {
    final ret = item.runtimeType.toString();

    if (ret.endsWith('Impl')) {
      return ret.substring(0, ret.length - 4);
    }

    return ret;
  }

  Iterable<Map<String, dynamic>> itemToMap(ElementItem metadata) =>
      mappableToMap((analyzer: metadata.analyzer, item: metadata.item));

  Iterable<Map<String, dynamic>> mappableToMap(MappableItem metadata) {
    final ret = <Map<String, dynamic>>[];
    final items =
        metadata.item is Iterable ? metadata.item as Iterable : [metadata.item];

    for (final item in items) {
      final toAdd = <String, dynamic>{};

      for (final prop in metadata.analyzer.properties) {
        final value = prop.getter(item);
        final map = <String, dynamic>{
          'type': prop.type.toString(),
          'valueType': value?.runtimeType.toString()
        };
        ValueKind kind;

        if (prop case ReflectIterableProperty<T, T> refit) {
          final list = refit.getter(item);

          kind = ValueKind.list;

          map['length'] = list.length;

          if (prop.isCore) {
            map['value'] = list.map((it) => it.toString()).toList();
          } else {
            if (prop.isViewable) {
              map['viewable'] = true;
            }
          }
        } else {
          if (prop.isCore) {
            kind = ValueKind.constant;

            map['value'] = prop.getter(item);
          } else if (prop.isViewable) {
            kind = ValueKind.known;

            map['value'] = {'type': runtimeTypeName(item)};
          } else {
            kind = ValueKind.unknown;
            map['value'] = runtimeTypeName(prop.getter(item));
          }
        }

        toAdd[prop.name] = map..['kind'] = kind.name;
      }

      ret.add(toAdd);
    }

    return ret;
  }

  ReflectItem findByCheck(Object? obj) {
    final ret = reflectedItems.firstWhereOrNull((it) => it.checker(obj));

    if (ret == null) {
      print(
          'FindByCheck aux ${obj.runtimeType}: \n${reflectedItems.map((i) => ' -- ${i.type}: ${i.checker(obj)}').join('\n')}');
      throw 'Couldnt find element item from check: $obj (${obj.runtimeType})';
    }

    return ret;
  }
}

extension UtilsTreeItems<T extends Object> on Iterable<ElementItem<T>> {
  Iterable<ElementItem<T>> sortedByLocation() {
    final items = toList();

    return items
      ..sort((a, b) {
        final cmp = a.node.end.compareTo(b.node.end);

        if (cmp == 0) {
          return a.node.offset.compareTo(b.node.offset);
        }

        return cmp;
      });
  }
}

import 'package:analyzer/dart/element/element.dart';

final types = [
  (
    checker: (Element element) => element is LibraryElement,
    properties: [
      (
        getter: (LibraryElement element) => element.topLevelElements,
        type: Element,
        isArray: true,
        name: 'topLevelElements',
      )
    ]
  )
];

final analyzerMetadata = AnalyzerElement<LibraryElement>(properties: [
  AnalyzerIterableProperty<LibraryElement, Element>(
      getter: (element) => element.topLevelElements,
      name: 'topElements',
      type: Element)
]);

sealed class AnalyzerProperty<P extends Element, T> {
  AnalyzerProperty({required this.name, required this.type});

  Object Function(P parent) get getter;
  final String name;
  final Type type;
}

final class AnalyzerSingleProperty<P extends Element, T extends Element>
    extends AnalyzerProperty<P, T> {
  AnalyzerSingleProperty(
      {required super.name, required super.type, required this.getter});

  @override
  final T Function(P parent) getter;
}

final class AnalyzerIterableProperty<P extends Element, T extends Element>
    extends AnalyzerProperty<P, Iterable<T>> {
  AnalyzerIterableProperty(
      {required super.name, required super.type, required this.getter});

  @override
  final Iterable<T> Function(P parent) getter;
}

class AnalyzerElement<T extends Element> {
  AnalyzerElement({required this.properties});

  final Iterable<AnalyzerProperty> properties;

  Type get type => T;

  bool checker(Element element) => element is T;
}

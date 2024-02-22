import 'package:analyzer/dart/element/element.dart';
import 'generator/reflector.dart';

@ReflectorInfo([
  LibraryElement,
  ClassElement,
  FunctionElement,
  MixinElement,
  VariableElement,
  TypeAliasElement
])
import 'metadata.analyzer.dart';

final reflectedElements = $reflectedElement;
